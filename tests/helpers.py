import importlib.util
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def load(path, name):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module
sys.path.insert(0, str(ROOT / "bootstrap"))
provision = load("bootstrap/provision.py", "provision")
pki = load("tools/lab_pki.py", "pki")
def config(role="broker"):
    return dict(node_name="kafka-broker-1" if role == "broker" else "kafka-controller-1",
                node_id=1 if role == "broker" else 100, role=role,
                fqdn="kafka-broker-1.kafka.internal" if role == "broker" else "kafka-controller-1.kafka.internal",
                zone="1", region="eastus", data_lun=0, data_disk_id="/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/kafka/providers/Microsoft.Compute/disks/kafka-broker-1-data", identity_client_id="00000000-0000-0000-0000-000000000002", cluster_id="AAAAAAAAAAAAAAAAAAAAAA",
                kafka_version="4.3.1", kafka_sha512="a" * 128, retention_hours=168,
                quorum="kafka-controller-1.kafka.internal:9093,kafka-controller-2.kafka.internal:9093,kafka-controller-3.kafka.internal:9093",
                initial_controllers="100@kafka-controller-1.kafka.internal:9093:BBBBBBBBBBBBBBBBBBBBBB",
                super_users="User:CN=kafka-admin;User:CN=kafka-broker-1",
                tls_secret_version="https://kafka-test.vault.azure.net/secrets/kafka-broker-1/" + "a" * 32)
