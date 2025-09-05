cat >> /home/ec2-user/.bashrc <<'BASHRC'
CRDB() {
  cockroach-sql sql --url "postgresql://${admin_user_name}@${db_host}:26257/defaultdb?sslmode=verify-full&sslrootcert=$HOME/certs/ca.crt&sslcert=$HOME/certs/client.${admin_user_name}.crt&sslkey=$HOME/certs/client.${admin_user_name}.key" "$@"
}
BASHRC