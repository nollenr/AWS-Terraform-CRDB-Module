%{ if wal_failover == "yes" }
echo "Creating /home/ec2-user/log_config..."
mkdir -p /home/ec2-user/log_config
cat <<EOF > /home/ec2-user/log_config/logs.yaml
file-defaults:
 buffered-writes: false
 auditable: false
 buffering:
   max-staleness: 1s
   flush-trigger-size: 256KiB
   max-buffer-size: 50MiB
EOF
%{ endif }
