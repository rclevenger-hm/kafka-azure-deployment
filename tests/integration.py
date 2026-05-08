#!/usr/bin/env python3
"""Run the real Kafka 4.3 runtime with TLS, ACLs and six isolated local processes."""
import argparse
import base64
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import uuid
from helpers import config, load, pki, provision

health = load("tools/health.py", "health")
smoke = load("tools/smoke.py", "smoke")


def kafka_uuid():
    return base64.urlsafe_b64encode(uuid.uuid4().bytes).decode().rstrip("=")
