#!/bin/bash -xe
set -euo pipefail
umask 077

# Ensure home & dirs
ADMIN_HOME="/home/${admin_user}"
install -d -m 700 "$ADMIN_HOME/.ssh"
install -d -m 700 "$ADMIN_HOME/certs"

echo "Setting up passwordless SSH for ${admin_user}"
# Write private key
cat > "$ADMIN_HOME/.ssh/id_rsa" <<'PEM'
${tls_private_key}
PEM
chown ${admin_user}:${admin_user} "$ADMIN_HOME/.ssh/id_rsa"
chmod 600 "$ADMIN_HOME/.ssh/id_rsa"

# Derive and install public key into authorized_keys
ssh-keygen -y -f "$ADMIN_HOME/.ssh/id_rsa" > "$ADMIN_HOME/.ssh/id_rsa.pub"
touch "$ADMIN_HOME/.ssh/authorized_keys"
chmod 600 "$ADMIN_HOME/.ssh/authorized_keys"
grep -qf "$ADMIN_HOME/.ssh/id_rsa.pub" "$ADMIN_HOME/.ssh/authorized_keys" || cat "$ADMIN_HOME/.ssh/id_rsa.pub" >> "$ADMIN_HOME/.ssh/authorized_keys"
chown -R ${admin_user}:${admin_user} "$ADMIN_HOME/.ssh"

echo "Installing TLS materials into $ADMIN_HOME/certs"
# CA cert
cat > "$ADMIN_HOME/certs/ca.crt" <<'PEM'
${tls_cert}
PEM
# Client cert
cat > "$ADMIN_HOME/certs/client.${admin_user_name}.crt" <<'PEM'
${tls_user_cert}
PEM
# Client key
cat > "$ADMIN_HOME/certs/client.${admin_user_name}.key" <<'PEM'
${tls_user_key}
PEM

chown -R ${admin_user}:${admin_user} "$ADMIN_HOME/certs"
chmod 600 "$ADMIN_HOME"/certs/*

# Convert client key to DER-encoded PKCS#8 for JDBC usage
openssl pkcs8 -topk8 -inform PEM -outform DER \
  -in "$ADMIN_HOME/certs/client.${admin_user_name}.key" \
  -out "$ADMIN_HOME/certs/client.${admin_user_name}.key.pk8" -nocrypt
chown ${admin_user}:${admin_user} "$ADMIN_HOME/certs/client.${admin_user_name}.key.pk8"
chmod 600 "$ADMIN_HOME/certs/client.${admin_user_name}.key.pk8"
