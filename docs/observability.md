# Observability

## Kafka metrics

The pinned JMX exporter exposes HTTP port 9404. Permit only private collector CIDRs; it has no authentication or TLS. Adapt [Prometheus targets](../monitoring/prometheus.yml.example) to node FQDNs and import the [Grafana dashboard](../monitoring/grafana-dashboard.json). Prometheus and Grafana servers are not provisioned.

Use the [alert rules](../monitoring/alerts.yml) for unavailable/under-replicated partitions, ISR pressure, controller availability and scrape loss. The alert fixture verifies selected conditions and recovery. Validate every metric name against the deployed Kafka/exporter version and record scrape labels consistently across environments.

## Azure telemetry

Each VM has an availability metric alert. Connect existing `action_group_ids` and test notification delivery; an empty list creates alert state without notifications. VNet flow logs default on using an existing regional Network Watcher and a separate private storage container/account policy. This module uses VNet flow logs rather than creating deprecated NSG flow logs.

Add organizational Azure Activity Log, Key Vault, Blob and OS log collection with suitable retention/access controls. Flow logs describe network traffic, not Kafka authorization or message contents. Boot diagnostics and Run Command assist startup investigation; never log TLS secret responses.

