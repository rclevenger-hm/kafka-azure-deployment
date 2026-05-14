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

    def test_refresh_script_stops_on_error(self):
        script = azure_admin.guest_script("refresh", True)
        self.assertTrue(script.startswith("set -eu\n"))
        self.assertIn("kafka-refresh --apply-change", script)
        self.assertIn("KAFKA_REFRESH_OK", script)

    def test_version_selected_explicitly(self):
        version = "2026-09-20T13:00:00.0000000Z"
        self.assertIn(version, azure_admin.guest_script("refresh", True, version))

    def test_no_shell_injection(self):
        for value in ("x; id", "$(id)", "a\nwhoami", "*", "broker-1 broker-2"):
            with self.subTest(value=value):
                with self.assertRaises(ValueError): azure_admin.build_command("kafka-rg", value, "status")

    def test_resource_group_injection(self):
        with self.assertRaises(ValueError): azure_admin.build_command("a;id", "kafka-broker-1", "status")

    def test_version_injection(self):
        with self.assertRaises(ValueError): azure_admin.guest_script("refresh", True, "$(id)")
