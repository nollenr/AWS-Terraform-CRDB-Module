ADMIN_HOME="/home/${admin_user}"

# Define a function the admin can run later
cat >> "$ADMIN_HOME/.bashrc" <<'BASHRC'
DBWORKLOAD_INSTALL() {
  sudo yum install -y gcc
  sudo yum install -y python3.11 python3.11-devel python3.11-pip.noarch || true
  pip3.11 install -U pip
  pip3.11 install "dbworkload[postgres]"

  mkdir -p "$HOME/workloads/bank"
  cd "$HOME/workloads/bank"
  wget -q https://raw.githubusercontent.com/fabiog1901/dbworkload/main/workloads/postgres/bank.py
  wget -q https://raw.githubusercontent.com/fabiog1901/dbworkload/main/workloads/postgres/bank.sql
  wget -q https://raw.githubusercontent.com/fabiog1901/dbworkload/main/workloads/postgres/bank.yaml
  cd "$HOME"
  dbworkload --version || true
}
BASHRC

# chown ${admin_user}:${admin_user} "$ADMIN_HOME/.bashrc"
