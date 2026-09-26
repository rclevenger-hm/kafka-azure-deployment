# Contributing

Explain the operational problem, changed behavior and validation evidence. Keep Azure infrastructure, bootstrap configuration and runbooks consistent. Preserve the original MIT notice and document cross-cloud adaptations.

## Local checks

Run `make check`, `make terraform` and `make integration`. The integration suite launches three controllers and three brokers on loopback and needs Java 17, OpenSSL, network access for pinned artifacts and adequate memory. Never run destructive cloud tests against a shared production environment.

