import hashlib
import io
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest.mock import patch
from helpers import provision
class ArtifactTests(unittest.TestCase):
    def test_checksum_success_and_cached_reuse(self):
        payload=b"verified artifact"; digest=hashlib.sha256(payload).hexdigest()
        with tempfile.TemporaryDirectory() as temp, patch.object(provision.urllib.request, "urlopen", return_value=io.BytesIO(payload)) as fetch:
            path=Path(temp)/"artifact"
            provision.download_verified("https://example.test/a", path, digest, "sha256")
            provision.download_verified("https://example.test/a", path, digest, "sha256")
            self.assertEqual(fetch.call_count, 1)
            self.assertEqual(path.read_bytes(), payload)
