#!/usr/bin/env python3
"""Read-only Kafka health gates for smoke tests and rolling maintenance."""
import argparse
import json
from pathlib import Path
import re
import subprocess


