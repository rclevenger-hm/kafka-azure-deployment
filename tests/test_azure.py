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
