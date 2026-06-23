import math
import unittest
from helpers import load
capacity=load("tools/capacity.py", "capacity")
class CapacityTests(unittest.TestCase):
    def test_failure_capacity_exceeds_normal(self):
        value=capacity.estimate(1, 24)
        self.assertGreater(value["failure_headroom_gib_per_survivor"], value["normal_gib_per_broker"])
        self.assertFalse(value["can_restore_full_replication_without_replacement"])
    def test_four_brokers_can_restore_three_replicas(self):
        self.assertTrue(capacity.estimate(1,24,brokers=4)["can_restore_full_replication_without_replacement"])
