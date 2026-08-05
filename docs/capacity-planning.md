# Capacity and cost

## Workload model

Record peak ingress, retention, record sizes, partitions, compression/compaction, skew, client p99, growth and RPO/RTO. `tools/capacity.py --help` exposes a conservative storage/throughput estimator; it is a planning aid rather than a benchmark. Allow free space and recovery bandwidth instead of sizing only steady-state writes.

## Defaults

Three Standard_D4s_v5 brokers use 500 GiB Premium SSD v2 disks, 3,000 IOPS and 125 MB/s each. Three Standard_D2s_v5 controllers use 50 GiB at the same base performance. Broker heap is 2 GiB and controller heap 1 GiB; leave memory for page cache and native allocations. Compare disk provisioned limits with VM uncached-disk/network limits. Confirm region/zone SKU availability and quotas before deployment.

Kafka RF3 multiplies storage and replication traffic. Benchmark realistic compression, record sizes, partition counts and consumer fanout. Measure recovery with one broker down and normal traffic present. Retention settings do not guarantee space when skew or compaction differs from the model.

