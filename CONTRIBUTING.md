# Contributing

Explain the operational problem, changed behavior and validation evidence. Keep Azure infrastructure, bootstrap configuration and runbooks consistent. Preserve the original MIT notice and document cross-cloud adaptations.

## Local checks

Run `make check`, `make terraform` and `make integration`. The integration suite launches three controllers and three brokers on loopback and needs Java 17, OpenSSL, network access for pinned artifacts and adequate memory. Never run destructive cloud tests against a shared production environment.

## Review requirements

Test changed trust boundaries and failure behavior. New credentials must use managed identity or an approved federated path; do not embed secrets. Keep runtime rolls separate from infrastructure convergence. Review disk identity, TLS validation, provider changes and any replacement plan carefully. Report live Azure tests separately from mocks, including source revision and environment.

## History

The initial retrospective sequence is documented in NOTICE. New maintenance commits should use their actual dates. Do not rewrite published history or imply that reconstructed timestamps establish historical activity.
