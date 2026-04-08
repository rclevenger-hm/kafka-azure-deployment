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


def run(*args, **kwargs):
    return subprocess.run(args, check=True, text=True, timeout=300, **kwargs)


def atomic_write(path, value, mode=0o640):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(value)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temp, mode)
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


def validate_config(c):
    patterns = {
        "node_name": r"[a-z][a-z0-9-]{2,50}", "fqdn": r"[a-z][a-z0-9.-]+",
        "zone": r"[1-3]",
        "region": r"[a-z][a-z0-9]{2,30}", "data_disk_id": azure.DISK_ID,
        "identity_client_id": azure.UUID, "cluster_id": r"[A-Za-z0-9_-]{22}",
        "kafka_version": r"4\.3\.[0-9]+", "kafka_sha512": r"[a-f0-9]{128}",
        "quorum": r"[a-z0-9.,:-]+", "initial_controllers": r"[A-Za-z0-9_.,:@-]+",
        "super_users": r"User:CN=[a-zA-Z0-9._-]+(?:;User:CN=[a-zA-Z0-9._-]+)*",
    }
    for field, pattern in patterns.items():
        if not isinstance(c.get(field), str) or not re.fullmatch(pattern, c[field]):
            raise ValueError("Invalid configuration field: " + field)
    if c.get("data_lun") != 0 or type(c.get("data_lun")) is not int:
        raise ValueError("The dedicated Kafka disk must use LUN zero")
    if c.get("role") not in {"broker", "controller"}:
        raise ValueError("Dedicated broker or controller role required")
    for field in ("node_id", "retention_hours"):
        if type(c.get(field)) is not int or c[field] < 1:
            raise ValueError("Invalid positive integer: " + field)


def render_properties(c, root="/var/lib/kafka", tls="/etc/kafka/tls"):
    validate_config(c)
    config = {
        "process.roles": c["role"], "node.id": c["node_id"],
        "controller.quorum.bootstrap.servers": c["quorum"],
        "controller.listener.names": "CONTROLLER",
        "listener.security.protocol.map": "CLIENT:SSL,BROKER:SSL,CONTROLLER:SSL",
        "inter.broker.listener.name": "BROKER",
        "listeners": "CONTROLLER://0.0.0.0:9093" if c["role"] == "controller" else "CLIENT://0.0.0.0:9092,BROKER://0.0.0.0:9094",
        "log.dirs": root + "/data", "metadata.log.dir": root + "/metadata",
        "ssl.keystore.type": "PEM", "ssl.keystore.location": tls + "/node.pem",
        "ssl.truststore.type": "PEM", "ssl.truststore.location": tls + "/ca.pem",
        "ssl.client.auth": "required", "ssl.endpoint.identification.algorithm": "https",
        "ssl.enabled.protocols": "TLSv1.3,TLSv1.2",
        "authorizer.class.name": "org.apache.kafka.metadata.authorizer.StandardAuthorizer",
        "allow.everyone.if.no.acl.found": "false", "super.users": c["super_users"],
        "auto.create.topics.enable": "false", "unclean.leader.election.enable": "false",
        "default.replication.factor": 3, "min.insync.replicas": 2,
        "offsets.topic.replication.factor": 3, "transaction.state.log.replication.factor": 3,
        "transaction.state.log.min.isr": 2, "log.retention.hours": c["retention_hours"],
        "num.partitions": 3,
    }
    if c["role"] == "controller":
        config["advertised.listeners"] = f"CONTROLLER://{c['fqdn']}:9093"
    if c["role"] == "broker":
        config["advertised.listeners"] = f"CLIENT://{c['fqdn']}:9092,BROKER://{c['fqdn']}:9094"
        config["broker.rack"] = c["zone"]
    return "".join(f"{key}={value}\n" for key, value in config.items())


def verify_identity(root, cluster_id, node_id):
    """Never overwrite foreign, incomplete or nonempty unformatted storage."""
    paths = [Path(root) / "data", Path(root) / "metadata"]
    found = []
    for path in paths:
        meta = path / "meta.properties"
        if meta.exists():
            values = dict(line.split("=", 1) for line in meta.read_text().splitlines() if "=" in line and not line.startswith("#"))
            if values.get("cluster.id") != cluster_id or values.get("node.id") != str(node_id):
                raise ValueError("Disk cluster/node identity does not match configuration")
            found.append(True)
        else:
            if path.exists() and any(path.iterdir()):
                raise ValueError("Refusing to format a nonempty directory without identity")
            found.append(False)
    if any(found) and not all(found):
        raise ValueError("Partial storage identity; operator recovery required")
    return all(found)


def download_verified(url, destination, expected, algorithm="sha512"):
    if not url.startswith("https://"):
        raise ValueError("Artifacts require HTTPS")
    destination = Path(destination)
    if destination.exists() and hashlib.new(algorithm, destination.read_bytes()).hexdigest() == expected:
        return
    temp = destination.with_suffix(destination.suffix + ".partial")
    digest = hashlib.new(algorithm)
    try:
        with urllib.request.urlopen(url, timeout=120) as response, temp.open("wb") as output:
            while chunk := response.read(1024 * 1024):
                digest.update(chunk)
                output.write(chunk)
        if digest.hexdigest() != expected:
            raise ValueError("Artifact checksum mismatch")
        os.replace(temp, destination)
    finally:
        temp.unlink(missing_ok=True)



def download_kafka(version, destination, expected):
    """Use the release CDN, falling back only when a release has been archived."""
    artifact = f"kafka_2.13-{version}.tgz"
    try:
        download_verified(f"https://dlcdn.apache.org/kafka/{version}/{artifact}", destination, expected)
    except urllib.error.HTTPError as error:
        if error.code not in (404, 410):
            raise
        download_verified(f"https://archive.apache.org/dist/kafka/{version}/{artifact}", destination, expected)


def extract_verified(archive, destination):
    with tarfile.open(archive) as tar:
        base = Path(destination).resolve()
        for member in tar.getmembers():
            target = (base / member.name).resolve()
            if not target.is_relative_to(base) or not (member.isfile() or member.isdir()):
                raise ValueError("Unsafe archive member")
        tar.extractall(destination)  # all paths and types checked above


def select_data_device(blocks, resolved):
    """Accept only the Azure LUN symlink's dedicated SCSI disk, never OS/temp disks."""
    if not re.fullmatch(r"/dev/sd[a-z]+", str(resolved)):
        raise ValueError("Expected an Azure SCSI data disk; NVMe requires a different implementation")
    matches = [b for b in blocks if b.get("name") == str(resolved)]
    if len(matches) != 1:
        raise ValueError("Missing or ambiguous data device")
    disk = matches[0]
    mounts = disk.get("mountpoints") or [disk.get("mountpoint")]
    if disk.get("type") != "disk" or disk.get("children") or any(m not in (None, "", "/var/lib/kafka") for m in mounts):
        raise ValueError("Refusing partitioned, OS, temporary, or foreign-mounted disk")
    return Path(resolved)


def mount_data(disk_id, lun):
    link = Path(f"/dev/disk/azure/scsi1/lun{lun}")
    for _ in range(60):
        if azure.verify_disk(azure.disk_metadata(), disk_id, lun) and link.is_block_device():
            blocks = json.loads(run("lsblk", "--json", "--paths", "--output", "NAME,TYPE,MOUNTPOINTS", capture_output=True).stdout)["blockdevices"]
            device = select_data_device(blocks, str(link.resolve()))
            break
        time.sleep(5)
    else:
        raise RuntimeError("Expected managed data disk did not attach within five minutes")
    signatures = json.loads(run("wipefs", "--json", str(device), capture_output=True).stdout)["signatures"]
    if not signatures:
        run("mkfs.ext4", "-m", "0", str(device))
    fs = run("blkid", "-s", "TYPE", "-o", "value", str(device), capture_output=True).stdout.strip()
    if fs != "ext4":
        raise ValueError("Expected ext4; refusing to reformat an existing filesystem")
    uuid = run("blkid", "-s", "UUID", "-o", "value", str(device), capture_output=True).stdout.strip()
    mount = Path("/var/lib/kafka")
    mount.mkdir(exist_ok=True)
    fstab = Path("/etc/fstab")
    lines = fstab.read_text().splitlines()
    entries = [line for line in lines if not line.lstrip().startswith("#") and len(line.split()) > 1 and line.split()[1] == str(mount)]
    if entries and not all(line.split()[0] == "UUID=" + uuid for line in entries):
        raise ValueError("Conflicting data disk mount in fstab")
    if not entries:
        atomic_write(fstab, "\n".join(lines) + f"\nUUID={uuid} {mount} ext4 defaults,noatime 0 2\n", 0o644)
    if os.path.ismount(mount):
        actual = run("findmnt", "-n", "-o", "UUID", "--target", str(mount), capture_output=True).stdout.strip()
        if actual != uuid:
            raise ValueError("Wrong filesystem mounted at Kafka data path")
    else:
        if any(mount.iterdir()):
            raise ValueError("Refusing to hide existing files beneath the data mount")
        run("mount", str(mount))
    return mount


def install_tls(bundle, config, directory):
    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    for key in ("certificate", "private_key", "ca"):
        if not isinstance(bundle.get(key), str) or "-----BEGIN " not in bundle[key]:
            raise ValueError("Missing PEM material: " + key)
    # Validate the full bundle before replacing active files.
    with tempfile.TemporaryDirectory() as temp:
        temp = Path(temp)
        for key in ("certificate", "private_key", "ca"):
            atomic_write(temp / key, bundle[key], 0o600)
        run("openssl", "verify", "-CAfile", str(temp / "ca"), "-verify_hostname", config["fqdn"], str(temp / "certificate"), capture_output=True)
        run("openssl", "x509", "-in", str(temp / "certificate"), "-checkend", "86400", "-noout", capture_output=True)
        cert_pub = run("openssl", "x509", "-in", str(temp / "certificate"), "-pubkey", "-noout", capture_output=True).stdout
        key_pub = run("openssl", "pkey", "-in", str(temp / "private_key"), "-pubout", capture_output=True).stdout
        subject = run("openssl", "x509", "-in", str(temp / "certificate"), "-noout", "-subject", "-nameopt", "RFC2253", capture_output=True).stdout.strip()
        if cert_pub != key_pub or subject != "subject=CN=" + config["node_name"]:
            raise ValueError("TLS key or certificate principal does not match node")
        if "-----BEGIN PRIVATE KEY-----" not in bundle["private_key"]:
            raise ValueError("Use an unencrypted PKCS8 private key")
    atomic_write(directory / "node.pem", bundle["private_key"].strip() + "\n" + bundle["certificate"].strip() + "\n", 0o600)
    atomic_write(directory / "ca.pem", bundle["ca"], 0o600)


def provision(config_path, allow_change=False):
    c = json.loads(Path(config_path).read_text())
    validate_config(c)
    state = Path("/var/lib/kafka-runtime.json")
    runtime = Path(__file__).parent
    fingerprint = hashlib.sha256(json.dumps({"config": c, "files": {p.name: p.read_text() for p in runtime.iterdir() if p.name in {"provision.py", "azure.py", "kafka.service", "kafka.env", "jmx.yml"}}}, sort_keys=True).encode()).hexdigest()
    if state.exists() and json.loads(state.read_text())["fingerprint"] != fingerprint and not allow_change:
        raise RuntimeError("Runtime change pending. Follow the rolling-change runbook and use --apply-change on one healthy node at a time.")
    # An unchanged healthy refresh must not trigger an unnecessary restart.
    if state.exists() and json.loads(state.read_text())["fingerprint"] == fingerprint:
        active = subprocess.run(["systemctl", "is-active", "--quiet", "kafka.service"], timeout=15, capture_output=True)
        if active.returncode == 0:
            print("Runtime already applied and Kafka process active; use health checks for readiness.")
            return
    # Fail secret access before changing local services or packages.
    bundle = azure.secret_payload(c["tls_secret_version"], c["identity_client_id"])
    run("apt-get", "update", "-qq")
    run("apt-get", "install", "-y", "--no-install-recommends", "openjdk-17-jre-headless", "openssl", "e2fsprogs", "util-linux", "ca-certificates")
    atomic_write("/etc/apt/apt.conf.d/52kafka-no-reboots", 'Unattended-Upgrade::Automatic-Reboot "false";\n', 0o644)
    try:
        pwd.getpwnam("kafka")
    except KeyError:
        run("useradd", "--system", "--home-dir", "/var/lib/kafka", "--shell", "/usr/sbin/nologin", "kafka")
    root = mount_data(c["data_disk_id"], c["data_lun"])
    formatted = verify_identity(root, c["cluster_id"], c["node_id"])
    artifact_name = "kafka_2.13-" + c["kafka_version"]
    target = Path("/opt/" + artifact_name + "-" + c["kafka_sha512"][:12])
    archive = Path("/var/cache/kafka_2.13-" + c["kafka_version"] + ".tgz")
    download_kafka(c["kafka_version"], archive, c["kafka_sha512"])
    if not (target / ".verified").exists() or (target / ".verified").read_text().strip() != c["kafka_sha512"]:
        with tempfile.TemporaryDirectory(dir="/opt") as staging:
            extract_verified(archive, staging)
            if target.exists():
                raise ValueError("Existing binary directory has no matching verified marker; operator recovery required")
            shutil.move(str(Path(staging) / artifact_name), target)
            atomic_write(target / ".verified", c["kafka_sha512"], 0o644)
    download_verified(JMX_URL, "/opt/kafka-jmx.jar", JMX_SHA256, "sha256")
    with tempfile.TemporaryDirectory() as tls_check:
        install_tls(bundle, c, tls_check)
    # Stop only after all artifact, certificate and identity checks have succeeded.
    subprocess.run(["systemctl", "stop", "kafka.service"], check=False, timeout=180, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    install_tls(bundle, c, "/etc/kafka/tls")
    link = Path("/opt/kafka.next")
    link.unlink(missing_ok=True)
    link.symlink_to(target)
    os.replace(link, "/opt/kafka")
    atomic_write("/etc/kafka/server.properties", render_properties(c))
    env = (runtime / "kafka.env").read_text()
    if c["role"] == "controller":
        env = env.replace("2g", "1g")
    atomic_write("/etc/kafka/kafka.env", env)
    atomic_write("/etc/kafka/jmx.yml", (runtime / "jmx.yml").read_text())
    atomic_write("/etc/systemd/system/kafka.service", (runtime / "kafka.service").read_text(), 0o644)
    for path in (root / "data", root / "metadata", Path("/var/log/kafka")):
        path.mkdir(parents=True, exist_ok=True)
    run("chown", "-R", "kafka:kafka", "/etc/kafka")
    account = pwd.getpwnam("kafka")
    for path in (root, root / "data", root / "metadata", Path("/var/log/kafka")):
        os.chown(path, account.pw_uid, account.pw_gid)
    if not formatted:
        command = ["runuser", "-u", "kafka", "--", "/opt/kafka/bin/kafka-storage.sh", "format", "--cluster-id", c["cluster_id"], "--config", "/etc/kafka/server.properties"]
        command += ["--initial-controllers", c["initial_controllers"]] if c["role"] == "controller" else ["--no-initial-controllers"]
        run(*command)
    run("systemctl", "daemon-reload")
    run("systemctl", "enable", "--now", "kafka.service")
    run("systemctl", "is-active", "--quiet", "kafka.service")
    atomic_write(state, json.dumps({"fingerprint": fingerprint, "cluster_id": c["cluster_id"], "node_id": c["node_id"]}) + "\n", 0o600)
    print("Kafka process started. Verify quorum and replicated produce/consume before accepting traffic.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True)
    parser.add_argument("--apply-change", action="store_true")
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error("Provisioning requires root on a dedicated Azure VM")
    provision(args.config, args.apply_change)
