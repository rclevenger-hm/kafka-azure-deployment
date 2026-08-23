# Observability

## Kafka metrics

The pinned JMX exporter exposes HTTP port 9404. Permit only private collector CIDRs; it has no authentication or TLS. Adapt [Prometheus targets](../monitoring/prometheus.yml.example) to node FQDNs and import the [Grafana dashboard](../monitoring/grafana-dashboard.json). Prometheus and Grafana servers are not provisioned.

Use the [alert rules](../monitoring/alerts.yml) for unavailable/under-replicated partitions, ISR pressure, controller availability and scrape loss. The alert fixture verifies selected conditions and recovery. Validate every metric name against the deployed Kafka/exporter version and record scrape labels consistently across environments.

