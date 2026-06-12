import json
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch
import urllib.error

from helpers import config, load, provision
import azure
refresh = load("bootstrap/refresh.py", "refresh")


class ManagedDiskTests(unittest.TestCase):
    def metadata(self, **changes):
        value = {"lun": "0", "managedDisk": {"id": config()["data_disk_id"]}}
        value.update(changes)
        return value

    def disk(self, **changes):
        value = dict(name="/dev/sdc", type="disk", mountpoints=[None])
        value.update(changes)
        return value

    def test_exact_managed_disk_and_lun_required(self):
        self.assertTrue(azure.verify_disk([self.metadata()], config()["data_disk_id"], 0))
        self.assertFalse(azure.verify_disk([self.metadata(lun="1")], config()["data_disk_id"], 0))

    def test_resource_ids_are_case_insensitive(self):
        self.assertTrue(azure.verify_disk([self.metadata()], config()["data_disk_id"].upper(), 0))

    def test_wrong_disk_identity_fails_before_format(self):
        with self.assertRaises(ValueError):
            azure.verify_disk([self.metadata(managedDisk={"id": "foreign"})], config()["data_disk_id"], 0)

    def test_duplicate_lun_is_rejected(self):
        with self.assertRaises(ValueError):
            azure.verify_disk([self.metadata(), self.metadata()], config()["data_disk_id"], 0)

    def test_invalid_lun_values_are_rejected(self):
        for lun in [-1, 64, True, "0"]:
            with self.subTest(lun=lun), self.assertRaises(ValueError):
                azure.verify_disk([], config()["data_disk_id"], lun)

    def test_invalid_cloud_disk_id_rejected(self):
        with self.assertRaises(ValueError): azure.verify_disk([], "/dev/sda", 0)

    def test_selected_lun_survives_device_enumeration_changes(self):
        for path in ["/dev/sdc", "/dev/sdd"]:
            self.assertEqual(provision.select_data_device([self.disk(name=path)], path), Path(path))

    def test_missing_or_duplicate_device_fails_closed(self):
        for disks in [[], [self.disk(), self.disk()]]:
            with self.subTest(disks=disks), self.assertRaises(ValueError):
                provision.select_data_device(disks, "/dev/sdc")

    def test_partitioned_data_disk_is_rejected(self):
        with self.assertRaises(ValueError):
            provision.select_data_device([self.disk(children=[{"name": "/dev/sdc1"}])], "/dev/sdc")

    def test_os_temp_and_foreign_mounts_are_rejected(self):
        for mount in ["/", "/mnt", "/home", "/var/lib/other"]:
            with self.subTest(mount=mount), self.assertRaises(ValueError):
                provision.select_data_device([self.disk(mountpoints=[mount])], "/dev/sdc")

    def test_kafka_mount_is_accepted(self):
        self.assertEqual(provision.select_data_device([self.disk(mountpoints=["/var/lib/kafka"])], "/dev/sdc"), Path('/dev/sdc'))

    def test_nvme_and_injected_device_paths_are_rejected(self):
        for path in ["/dev/nvme0n1", "/dev/sdc;reboot", "/dev/sdc1"]:
            with self.subTest(path=path), self.assertRaises(ValueError):
                provision.select_data_device([self.disk(name=path)], path)


class ManagedIdentityTests(unittest.TestCase):
    def test_explicit_identity_and_audience_requested(self):
        with patch.object(azure, 'request', return_value=(b'{"access_token":"private-token"}', {})) as call:
            self.assertEqual(azure.token(config()['identity_client_id'], 'https://vault.azure.net'), 'private-token')
            self.assertIn('client_id=' + config()['identity_client_id'], call.call_args.args[0])
            self.assertIn('resource=https%3A%2F%2Fvault.azure.net', call.call_args.args[0])
            self.assertEqual(call.call_args.args[1], {'Metadata': 'true'})

    def test_invalid_identity_or_resource_never_calls_imds(self):
        for identity, audience in [('bad', 'https://vault.azure.net'), (config()['identity_client_id'], 'https://attacker')]:
            with self.subTest(identity=identity, audience=audience), patch.object(azure, 'request') as call:
                with self.assertRaises(ValueError): azure.token(identity, audience)
                call.assert_not_called()

    def test_missing_token_fails_closed(self):
        with patch.object(azure, 'request', return_value=(b'{}', {})):
            with self.assertRaises(ValueError): azure.token(config()['identity_client_id'], 'https://vault.azure.net')

    def test_response_read_is_bounded(self):
        response = Mock()
        response.read.return_value = b'x' * 11
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        opener = Mock(); opener.open.return_value = response
        with patch.object(azure.urllib.request, 'build_opener', return_value=opener):
            with self.assertRaises(ValueError): azure.request('https://example.com', maximum=10)
        response.read.assert_called_once_with(11)

    def test_authenticated_redirects_are_forbidden(self):
        with self.assertRaises(ValueError): azure.NoRedirect().redirect_request(None, None, 302, '', {}, 'https://attacker')

    def test_http_access_denied_is_not_retried(self):
        opener = Mock(); opener.open.side_effect = urllib.error.HTTPError('https://vault', 403, 'denied', {}, None)
        with patch.object(azure.urllib.request, 'build_opener', return_value=opener), patch.object(azure.time, 'sleep') as sleep:
            with self.assertRaises(urllib.error.HTTPError): azure.request('https://vault')
            self.assertEqual(opener.open.call_count, 1)
            sleep.assert_not_called()


class KeyVaultTests(unittest.TestCase):
    def response(self, **changes):
        value = {'id': config()['tls_secret_version'], 'value': json.dumps({'certificate': 'test'})}
        value.update(changes)
        return json.dumps(value).encode(), {}

    def test_exact_version_requested(self):
        with patch.object(azure, 'token', return_value='token'), patch.object(azure, 'request', return_value=self.response()) as call:
            self.assertEqual(azure.secret_payload(config()['tls_secret_version'], config()['identity_client_id']), {'certificate': 'test'})
            self.assertEqual(call.call_args.args[0], config()['tls_secret_version'] + '?api-version=7.4')

    def test_wrong_response_identity_rejected(self):
        with patch.object(azure, 'token', return_value='token'), patch.object(azure, 'request', return_value=self.response(id='other')):
            with self.assertRaises(ValueError): azure.secret_payload(config()['tls_secret_version'], config()['identity_client_id'])
