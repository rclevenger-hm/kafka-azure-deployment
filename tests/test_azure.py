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
