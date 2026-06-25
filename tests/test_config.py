import unittest
from helpers import config, provision
class ConfigTests(unittest.TestCase):
    def props(self, role="broker"):
        return dict(line.split("=", 1) for line in provision.render_properties(config(role)).splitlines())
