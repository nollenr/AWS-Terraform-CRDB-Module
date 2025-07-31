echo "Appending CREATENODECERT function to .bashrc..."

cat <<'EOF' >> /home/ec2-user/.bashrc
CREATENODECERT() {
  cockroach cert create-node \
    $ip_local \
    $dns_private \
    $ip_public \
    $dns_public \
    localhost \
    127.0.0.1 \
EOF
if [ "${include_ha_proxy}" = "yes" ]; then echo "  ${ha_proxy_private_ip} \\" >> /home/ec2-user/.bashrc; fi
cat <<'EOF' >> /home/ec2-user/.bashrc
    --certs-dir=certs \
    --ca-key=my-safe-directory/ca.key
}
EOF

echo "Appending CREATEROOTCERT function to .bashrc..."

cat <<'EOF' >> /home/ec2-user/.bashrc
CREATEROOTCERT() {
    cockroach cert create-client \
    root \
    --certs-dir=certs \
    --ca-key=my-safe-directory/ca.key
}
EOF
