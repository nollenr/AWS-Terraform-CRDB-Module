echo "Validating if init needs to be run, creating the admin user, and installing licenses"
echo "RunInit: ${run_init}  Count.Index: ${index}  Count: ${crdb_nodes}"

if [[ '${run_init}' = 'yes' && $(( ${index} + 1 )) -eq ${crdb_nodes} ]]; then
  echo "Initializing Cockroach Database"
  su ec2-user -lc 'cockroach init'
fi

if [[ '${run_init}' = 'yes' && $(( ${index} + 1 )) -eq ${crdb_nodes} && '${create_admin_user}' = 'yes' ]]; then
  echo "Creating admin user: ${admin_user_name}"
  su ec2-user -lc 'cockroach sql --execute "CREATE USER ${admin_user_name}; GRANT admin TO ${admin_user_name};"'
fi

if [[ '${run_init}' = 'yes' && $(( ${index} + 1 )) -eq ${crdb_nodes} && '${install_enterprise_keys}' = 'yes' ]]; then
  echo "Installing enterprise license settings for organization: ${cluster_organization}"
  su ec2-user -lc 'cockroach sql --execute "SET CLUSTER SETTING cluster.organization = '\''${cluster_organization}'\'';"'
  echo "Installing enterprise license key: ${enterprise_license}"
  su ec2-user -lc 'cockroach sql --execute "SET CLUSTER SETTING enterprise.license = '\''${enterprise_license}'\'';"'
fi
