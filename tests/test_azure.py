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
