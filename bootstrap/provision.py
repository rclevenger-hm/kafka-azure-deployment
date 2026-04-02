#!/usr/bin/env python3
"""Provision one private Kafka node. No cloud credentials or TLS payloads in state."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import pwd
import re
import shutil
import subprocess
import tarfile
import tempfile
import time
import urllib.error
import urllib.request

import azure

JMX_URL = "https://github.com/prometheus/jmx_exporter/releases/download/1.1.0/jmx_prometheus_javaagent-1.1.0.jar"
JMX_SHA256 = "2d158db7a4cd2999f40ca30a2532bc8456ca3ecf37498cbe60a02a588bf3c9f1"


