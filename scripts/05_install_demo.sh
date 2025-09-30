ADMIN_HOME="/home/ec2-user"

# Define the demo install function
cat >> "$ADMIN_HOME/.bashrc" <<'BASHRC'
MULTIREGION_DEMO_INSTALL() {

  sudo yum install -y gcc gcc-c++ libpq-devel
  sudo yum install -y python3.11 python3.11-devel python3.11-pip.noarch || true
  sudo yum install -y git
  pip3.11 install "sqlalchemy~=1.4" sqlalchemy-cockroachdb psycopg2

  # Get the demo
  if [ ! -d "$HOME/crdb-multi-region-demo" ]; then
    git clone https://github.com/nollenr/crdb-multi-region-demo.git "$HOME/crdb-multi-region-demo"
  fi

  # Build DB configure SQL
  cat > "$HOME/crdb-multi-region-demo/sql/db_configure.sql" <<SQL
DROP DATABASE IF EXISTS movr_demo;
CREATE DATABASE movr_demo;
ALTER DATABASE movr_demo SET PRIMARY REGION = "${primary_region}";
ALTER DATABASE movr_demo ADD REGION "${secondary_region}";
ALTER DATABASE movr_demo ADD REGION "${tertiary_region}";
ALTER DATABASE movr_demo SURVIVE REGION FAILURE;
SQL

  # Run configure/import only on the designated primary region host
  if [[ "${primary_region}" == "${region_01}" ]]; then
    URL="postgresql://${admin_user_name}@${db_host}:26257/defaultdb?sslmode=verify-full&sslrootcert=/home/${admin_user}/certs/ca.crt&sslcert=/home/${admin_user}/certs/client.${admin_user_name}.crt&sslkey=/home/${admin_user}/certs/client.${admin_user_name}.key"
    cockroach-sql sql --url "$URL" --file "$HOME/crdb-multi-region-demo/sql/db_configure.sql"
    cockroach-sql sql --url "$URL" --file "$HOME/crdb-multi-region-demo/sql/import.sql"
  fi
}
BASHRC

# Demo environment variables for the app
{
  echo "# Demo application environment"
  echo "export DB_HOST=\"${db_host}\""
  echo "export DB_USER=\"${admin_user_name}\""
  echo "export DB_SSLCERT=\"/home/${admin_user}/certs/client.${admin_user_name}.crt\""
  echo "export DB_SSLKEY=\"/home/${admin_user}/certs/client.${admin_user_name}.key\""
  echo "export DB_SSLROOTCERT=\"/home/${admin_user}/certs/ca.crt\""
  echo "export DB_SSLMODE=\"require\""
} >> "$ADMIN_HOME/.bashrc"

# Optionally kick off the demo install automatically (matches your original logic)
if [[ "${include_demo}" == "yes" ]]; then
  echo "Installing Demo shortly..."
  sleep 60
  su ${admin_user} -lc 'MULTIREGION_DEMO_INSTALL'
fi

chown ${admin_user}:${admin_user} "$ADMIN_HOME/.bashrc"
