echo "Appending CRDB control functions to /home/ec2-user/.bashrc..."

cat <<'EOF' >> /home/ec2-user/.bashrc

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
