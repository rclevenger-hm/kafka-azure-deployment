#!/usr/bin/env python3
"""Inspect or refresh exactly one Kafka VM through Azure Run Command."""
import argparse
import json
import re
import shlex
import subprocess


def guest_script(action, apply_change=False, version_id=None):
    if action not in {"status", "refresh"}:
        raise ValueError("Unsupported action")
    if action == "status":
        if apply_change or version_id is not None:
            raise ValueError("Status does not accept runtime mutation options")
        return "\n".join([
            "set -eu", "systemctl --no-pager status kafka-bootstrap.service kafka.service || true",
            "findmnt /var/lib/kafka || true", "df -h /var/lib/kafka",
            "if test -f /opt/kafka-bootstrap/blob-version.txt; then cat /opt/kafka-bootstrap/blob-version.txt; fi",
        ])
    command = ["/usr/local/sbin/kafka-refresh"]
    if apply_change:
        command.append("--apply-change")
    if version_id is not None:
        if not re.fullmatch(r"[0-9T:.Z-]{20,40}", version_id):
            raise ValueError("Invalid immutable Blob version ID")
        command.extend(["--version-id", version_id])
    return "set -eu\n" + shlex.join(command) + "\nprintf 'KAFKA_REFRESH_OK\\n'\n"


def build_command(resource_group, node, action, apply_change=False, version_id=None):
    if not re.fullmatch(r"[A-Za-z0-9_().-]{1,90}", resource_group):
        raise ValueError("Invalid resource group")
    if not re.fullmatch(r"[a-z][a-z0-9-]{2,50}", node):
        raise ValueError("Select exactly one valid Kafka node name")
    return ["az", "vm", "run-command", "invoke", "--resource-group", resource_group,
            "--name", node, "--command-id", "RunShellScript", "--scripts",
            guest_script(action, apply_change, version_id), "--output", "json"]
