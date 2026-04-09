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
