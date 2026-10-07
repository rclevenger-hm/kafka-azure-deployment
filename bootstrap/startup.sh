#!/usr/bin/env bash
set -euo pipefail
umask 077
# Reviewed Ubuntu 24.04 Gen2 includes Python 3 and the Azure VM agent.
command -v python3 >/dev/null
install -d -m 0700 /usr/local/lib/kafka-bootstrap /opt/kafka-bootstrap
cat > /etc/kafka-bootstrap.json <<'CONFIG'
${settings}
CONFIG
cat > /usr/local/lib/kafka-bootstrap/azure.py <<'AZURE'
${azure_source}
AZURE
cat > /usr/local/lib/kafka-bootstrap/refresh.py <<'REFRESH'
${refresh_source}
REFRESH
cat > /usr/local/sbin/kafka-refresh <<'LAUNCH'
#!/usr/bin/env bash
set -euo pipefail
exec python3 /usr/local/lib/kafka-bootstrap/refresh.py "$@"
LAUNCH
chmod 0700 /usr/local/sbin/kafka-refresh
cat > /etc/systemd/system/kafka-bootstrap.service <<'SERVICE'
[Unit]
Description=Initial Kafka bootstrap after managed disk and RBAC readiness
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/var/lib/kafka-runtime.json
StartLimitIntervalSec=0

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/kafka-refresh
RemainAfterExit=yes
Restart=on-failure
RestartSec=30
TimeoutStartSec=2400
UMask=0077

[Install]
WantedBy=multi-user.target
SERVICE
systemctl daemon-reload
systemctl enable kafka-bootstrap.service
systemctl start --no-block kafka-bootstrap.service
