#!/usr/bin/env python3
"""Create a unique RF3 topic, verify exact roundtrip, and delete only that topic."""
import argparse
import json
from pathlib import Path
import subprocess
import time
import uuid


