echo "Appending CRDB control functions to /home/ec2-user/.bashrc..."

cat <<'EOF' >> /home/ec2-user/.bashrc
CRDB_UPDATE_NODE_IDS() {
  # Pull node status as TSV for easy parsing
  local tsv
  if ! tsv=$(cockroach node status --format=tsv $${CRDB_FLAGS:-} 2>/dev/null); then
    echo "Error: failed to run 'cockroach node status'." >&2
    return 1
  fi

  # Build and execute SQL updates directly
  local sql
  sql=$(
    echo "$tsv" \
    | awk -F'\t' 'NR>1 {
        # Columns: id | address | sql_address | build | started_at | updated_at | locality | is_available | is_live
        id=$1
        split($2, a, ":"); ip=a[1]
        gsub("\047", "\047\047", ip)
        printf "UPDATE public_and_private_ip_by_az SET node_id = %d WHERE private_ip = '\''%s'\'';\n", id, ip
      }'
  )

  if [[ -z "$sql" ]]; then
    echo "No rows found in 'cockroach node status' output." >&2
    return 1
  fi

  cockroach sql $${CRDB_FLAGS:-} <<SQL
BEGIN;
$${sql}
COMMIT;
SQL
}

STARTCRDB() {
  sudo systemctl start securecockroachdb
}

STOPCRDB() {
  sudo systemctl stop securecockroachdb
}

KILLCRDB() {
  sudo systemctl kill -s SIGKILL securecockroachdb
}

KILLREGIONCRDB() {
  for ip in $CLUSTER_PRIVATE_IP_LIST; do
    echo "Connecting to $ip..."
    ssh -o ConnectTimeout=5 "$ip" "KILLCRDB"
    echo "CRDB Killed on $ip"
  done
}

STOPREGIONCRDB() {
  for ip in $CLUSTER_PRIVATE_IP_LIST; do
    echo "Connecting to $ip..."
    ssh -o ConnectTimeout=5 "$ip" "STOPCRDB"
    echo "CRDB Stopped on $ip"
  done
}

STARTREGIONCRDB() {
  for ip in $CLUSTER_PRIVATE_IP_LIST; do
    echo "Connecting to $ip..."
    ssh -o ConnectTimeout=5 "$ip" "STARTCRDB"
    echo "CRDB Started on $ip"
  done
}

SETCRDBVARS() {
  cockroach node status | awk -F ':' 'FNR > 1 { print $1 }' | awk '{ print $1, $2 }' | while read line; do
    node_number=$(echo $line | awk '{ print $1 }')
    variable_name=CRDBNODE$node_number
    ip=$(echo $line | awk '{ print $2 }')
    echo export $variable_name=$ip >> crdb_node_list
  done
  source ./crdb_node_list
}

%{ for az, ips in az_to_private_ips ~}
KILL_${replace(az, "-", "_")}_CRDB() {
  for ip in ${join(" ", ips)}; do
    echo "Connecting to $ip..."
    ssh -o ConnectTimeout=5 "$ip" "KILLCRDB"
    echo "CRDB Killed on $ip"
  done
}

STOP_${replace(az, "-", "_")}_CRDB() {
  for ip in ${join(" ", ips)}; do
    echo "Connecting to $ip..."
    ssh -o ConnectTimeout=5 "$ip" "STOPCRDB"
    echo "CRDB Stopped on $ip"
  done
}

START_${replace(az, "-", "_")}_CRDB() {
  for ip in ${join(" ", ips)}; do
    echo "Connecting to $ip..."
    ssh -o ConnectTimeout=5 "$ip" "STARTCRDB"
    echo "CRDB Started on $ip"
  done
}
%{ endfor }


EOF
