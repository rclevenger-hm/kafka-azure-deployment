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
    def test_valid_identity_is_installed(self):
        target=Path(self.temp.name)/"valid"
        provision.install_tls(self.bundle,config(),target)
        self.assertEqual((target/"node.pem").stat().st_mode & 0o777,0o600)
        self.assertIn("BEGIN PRIVATE KEY",(target/"node.pem").read_text())
