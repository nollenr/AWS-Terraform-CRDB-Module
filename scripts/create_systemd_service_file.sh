echo "Creating systemd service file..."

cat <<EOF > /etc/systemd/system/securecockroachdb.service
[Unit]
Description=CockroachDB node
Requires=network.target
After=network-online.target

[Service]
Type=notify
WorkingDirectory=/home/ec2-user
EOF

if [[ ${is_single_node} == "true" && ${wal_failover} == "yes" ]]; then
  # echo 'ExecStart=/usr/local/bin/cockroach start-single-node --certs-dir=certs --max-offset=250ms --store=/mnt/crdb-data --log-config-file=/home/ec2-user/log_config/logs.yaml --wal-failover=path=/mnt/crdb-wal' >> /etc/systemd/system/securecockroachdb.service
  echo 'ExecStart=/usr/local/bin/cockroach start-single-node --certs-dir=certs --max-offset=250ms --cache=${cache} --max-sql-memory=${max_sql_memory} --store=/mnt/crdb-data --wal-failover=path=/mnt/crdb-wal' >> /etc/systemd/system/securecockroachdb.service
elif [[ ${is_single_node} == "true" && ${wal_failover} == "no" ]]; then
  echo 'ExecStart=/usr/local/bin/cockroach start-single-node --certs-dir=certs --max-offset=250ms --cache=${cache} --max-sql-memory=${max_sql_memory} --store=/mnt/crdb-data' >> /etc/systemd/system/securecockroachdb.service
elif [[ ${is_single_node} == "false" && ${wal_failover} == "yes" ]]; then
  # echo 'ExecStart=/usr/local/bin/cockroach start --locality=region=${region},zone=${availability_zone} --certs-dir=certs --advertise-addr=${advertise_address} --join=${join_string} --max-offset=250ms --store=/mnt/crdb-data --log-config-file=/home/ec2-user/log_config/logs.yaml --wal-failover=path=/mnt/crdb-wal' >> /etc/systemd/system/securecockroachdb.service
  echo 'ExecStart=/usr/local/bin/cockroach start --locality=region=${region},zone=${availability_zone} --certs-dir=certs --advertise-addr=${advertise_address} --join=${join_string} --max-offset=250ms --cache=${cache} --max-sql-memory=${max_sql_memory} --store=/mnt/crdb-data --wal-failover=path=/mnt/crdb-wal' >> /etc/systemd/system/securecockroachdb.service
else
  echo 'ExecStart=/usr/local/bin/cockroach start --locality=region=${region},zone=${availability_zone} --certs-dir=certs --advertise-addr=${advertise_address} --join=${join_string} --max-offset=250ms --cache=${cache} --max-sql-memory=${max_sql_memory} --store=/mnt/crdb-data' >> /etc/systemd/system/securecockroachdb.service
fi

cat <<EOF >> /etc/systemd/system/securecockroachdb.service
TimeoutStopSec=300
Restart=${systemd_restart_option}
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=cockroach
User=ec2-user
LimitNOFILE=35000

[Install]
WantedBy=default.target
EOF
