# Decision: separate runtime and VM lifecycle

## Context

A configuration update must not restart a controller majority or several brokers. VM custom-data/image changes can require replacement.

