import unittest
from helpers import load
health=load("tools/health.py","health")
class HealthTests(unittest.TestCase):
    def test_healthy_quorum(self):
        self.assertEqual(health.parse_quorum('LeaderId: 100\nMaxFollowerLag: 0\nCurrentVoters: [{"id":100},{"id":101},{"id":102}]')["voters"],3)
