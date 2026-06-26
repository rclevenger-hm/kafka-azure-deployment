import unittest
from helpers import config, provision
class ConfigTests(unittest.TestCase):
    def props(self, role="broker"):
        return dict(line.split("=", 1) for line in provision.render_properties(config(role)).splitlines())
    def test_broker_has_two_private_tls_listeners(self):
        p = self.props()
        self.assertEqual(p["listeners"], "CLIENT://0.0.0.0:9092,BROKER://0.0.0.0:9094")
        self.assertIn("CLIENT://kafka-broker-1.kafka.internal:9092", p["advertised.listeners"])
