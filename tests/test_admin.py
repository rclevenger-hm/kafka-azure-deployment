import contextlib
import io
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import azure_admin


class AdminTests(unittest.TestCase):
    def test_status_uses_agent_and_one_node(self):
        command = azure_admin.build_command("kafka-rg", "kafka-broker-1", "status")
        self.assertEqual(command[command.index("--name") + 1], "kafka-broker-1")
        self.assertNotIn("--apply-change", command[-3])
        self.assertIn("findmnt", command[-3])
