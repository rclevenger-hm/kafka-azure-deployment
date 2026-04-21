#!/usr/bin/env python3
"""Fetch the exact checksummed runtime used by Terraform for integration tests."""
import argparse
import importlib.util
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "bootstrap"))
spec = importlib.util.spec_from_file_location("provision", ROOT / "bootstrap/provision.py")
provision = importlib.util.module_from_spec(spec)
spec.loader.exec_module(provision)


