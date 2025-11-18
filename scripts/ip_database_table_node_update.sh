
if [[ '${run_init}' = 'yes' && $(( ${index} + 1 )) -eq ${crdb_nodes} && '${create_database_node_ip_table}' = 'yes' ]]; then
  echo "Update table cluster_node_ip_addresses with node IDs"
  su ec2-user -lc 'CRDB_UPDATE_NODE_IDS'
fi
