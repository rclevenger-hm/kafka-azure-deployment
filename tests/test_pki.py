import json
from pathlib import Path
import tempfile
import unittest
from helpers import config, pki, provision
class PkiTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp=tempfile.TemporaryDirectory(); cls.root=Path(cls.temp.name)/"pki"
        pki.create_ca(cls.root)
        cls.bundle=json.loads(pki.issue(cls.root,"kafka-broker-1","kafka-broker-1.kafka.internal").read_text())
    @classmethod
    def tearDownClass(cls): cls.temp.cleanup()
