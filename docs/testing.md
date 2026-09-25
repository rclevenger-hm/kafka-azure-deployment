# Verification

## Credential-free checks

`make check` runs standard-library Python regression tests, syntax checks, documentation links, dashboard JSON and shell syntax. Tests cover listener security, ACL defaults, disk signatures/identity, archives, PKI, health/capacity, bounded Azure requests, selected managed identities, pinned secret/blob responses and runtime restart guards. Azure administration tests exercise command construction and explicit mutation opt-in.

`make terraform` formats/initializes, validates real provider schemas and runs mocked plans. Mocks exercise topology, zones, private endpoints, role scopes, storage/performance, denied public inputs and other validation failures. The committed lockfile pins provider checksums. No credentials or cloud resources are needed.

## Real Kafka integration

`make integration` downloads checksum-verified Kafka 4.3.1 and JMX exporter, creates disposable TLS identities and starts three dedicated controllers plus three brokers on loopback with Java 17. It tests authenticated metadata/topic access, denied client authorization, exact RF3 roundtrip, writes while one broker is stopped, persisted recovery after restart and active controller leader failover. It cleans up processes and temporary data.

This test requires loopback sockets, internet artifact access and sufficient memory. It uses small heaps and bounded waits for CI. It does not invoke Azure APIs or emulate Azure network/storage failure behavior. Failed process logs identify the failing stage without exposing cloud secrets.

## CI

The GitHub workflow separates Python/repository checks, Terraform, Kafka integration and Prometheus rule checks. Pull requests need no cloud credentials. The manual Azure deployment workflow is separate, opt-in and uses a protected private runner.

