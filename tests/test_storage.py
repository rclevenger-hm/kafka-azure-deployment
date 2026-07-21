import tempfile
from pathlib import Path
import unittest
from helpers import provision
class StorageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.root = Path(self.temp.name)
    def tearDown(self): self.temp.cleanup()
    def identity(self, folder, cluster="cluster", node=1):
        path = self.root / folder; path.mkdir(exist_ok=True)
        (path / "meta.properties").write_text(f"# Kafka metadata\ncluster.id={cluster}\nnode.id={node}\nversion=1\n")
    def test_fresh_empty_disk_can_format(self):
        self.assertFalse(provision.verify_identity(self.root, "cluster", 1))
