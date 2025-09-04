# Adds a convenience function to ec2-user's shell
cat >> /home/ec2-user/.bashrc <<'BASHRC'
CRDB() {
  cockroach-sql sql --url "postgresql://${admin_user_name}@${haproxy_ip}:26257/defaultdb?sslmode=verify-full&sslrootcert=$HOME/certs/ca.crt&sslcert=$HOME/certs/client.${admin_user_name}.crt&sslkey=$HOME/certs/client.${admin_user_name}.key" "$@"
}
BASHRC
# chown ec2-user:ec2-user /home/ec2-user/.bashrc
