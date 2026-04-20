#!/usr/bin/env python3
"""Validate Python syntax, local documentation links and tracked asset references."""
import ast
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

