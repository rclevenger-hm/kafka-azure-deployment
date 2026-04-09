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


