# Capacity and cost

## Workload model

Record peak ingress, retention, record sizes, partitions, compression/compaction, skew, client p99, growth and RPO/RTO. `tools/capacity.py --help` exposes a conservative storage/throughput estimator; it is a planning aid rather than a benchmark. Allow free space and recovery bandwidth instead of sizing only steady-state writes.

