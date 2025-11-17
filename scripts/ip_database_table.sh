#!/usr/bin/env bash
set -euo pipefail

if [[ "${create_database_node_ip_table}" = "yes" ]]; then
  sleep 90  # wait for network to be fully up
  # --- IMDSv2 token ---
  TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60")

  # --- Instance metadata ---
  az=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/placement/availability-zone)

  region="$${az::-1}"

  private_ip=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/local-ipv4)

  # public-ipv4 can be missing if the instance has no public IP, so tolerate failure
  public_ip=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/public-ipv4 || true)

  # --- Create table exactly once (on the last node), still idempotent ---
  su ec2-user -lc "cockroach sql <<'SQL'
CREATE TABLE IF NOT EXISTS cluster_node_ip_addresses (
  region STRING,
  az STRING,
  public_ip STRING,
  private_ip STRING,
  node_id INT,
  primary key (region, private_ip)
);
SQL"

  # --- Every node upserts its own row ---
  su ec2-user -lc "cockroach sql <<SQL
UPSERT INTO cluster_node_ip_addresses (region, az, public_ip, private_ip)
VALUES ('$region', '$az', NULLIF('$public_ip',''), '$private_ip');
SQL"

  echo 'IP registration complete.'
else
  echo "Skipping database node IP table creation (create_database_node_ip_table != 'yes')"
fi

