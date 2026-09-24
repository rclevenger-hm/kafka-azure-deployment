# Verification

## Credential-free checks

`make check` runs standard-library Python regression tests, syntax checks, documentation links, dashboard JSON and shell syntax. Tests cover listener security, ACL defaults, disk signatures/identity, archives, PKI, health/capacity, bounded Azure requests, selected managed identities, pinned secret/blob responses and runtime restart guards. Azure administration tests exercise command construction and explicit mutation opt-in.

`make terraform` formats/initializes, validates real provider schemas and runs mocked plans. Mocks exercise topology, zones, private endpoints, role scopes, storage/performance, denied public inputs and other validation failures. The committed lockfile pins provider checksums. No credentials or cloud resources are needed.

