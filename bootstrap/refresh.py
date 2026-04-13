#!/usr/bin/env python3
"""Stage a node-specific Azure Blob runtime and apply it under an exclusive local lock."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

import azure

FILES = {"provision.py", "azure.py", "kafka.service", "kafka.env", "jmx.yml"}


def validate_manifest(manifest):
    if manifest.get("schema_version") != 1 or not isinstance(manifest.get("config"), dict):
        raise ValueError("Unsupported runtime manifest")
    files = manifest.get("files")
    if not isinstance(files, dict) or set(files) != FILES:
        raise ValueError("Unexpected runtime files")
    if not all(isinstance(value, str) and value for value in files.values()):
        raise ValueError("Runtime files must be nonempty text")
    return manifest


def refresh(allow_change=False, version_id=None):
    settings = json.loads(Path("/etc/kafka-bootstrap.json").read_text())
    with open("/run/kafka-refresh.lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        with tempfile.TemporaryDirectory(prefix="kafka-stage-", dir="/opt") as directory:
            stage = Path(directory)
            download = stage / "manifest.json"
            value, actual_version = azure.runtime_manifest(settings["blob_url"], settings["identity_client_id"], version_id)
            manifest = validate_manifest(value)
            download.write_text(json.dumps(manifest))
            for name, content in manifest["files"].items():
                (stage / name).write_text(content)
            (stage / "config.json").write_text(json.dumps(manifest["config"]))
            args = ["python3", str(stage / "provision.py"), "--config", str(stage / "config.json")]
            if allow_change:
                args.append("--apply-change")
            subprocess.run(args, check=True, timeout=1800)
            active = Path("/opt/kafka-bootstrap")
            active.mkdir(exist_ok=True, mode=0o700)
            for name in [*FILES, "config.json", "manifest.json"]:
                shutil.copyfile(stage / name, active / name)
                os.chmod(active / name, 0o600)
            (active / "blob-version.txt").write_text(actual_version + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply-change", action="store_true")
    parser.add_argument("--version-id", help="Optional recorded Azure blob version for controlled rollback")
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error("Run as root through an authorized administrative session")
    os.umask(0o077)
    refresh(args.apply_change, args.version_id)


if __name__ == "__main__":
    main()
