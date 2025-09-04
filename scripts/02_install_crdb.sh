# Common tooling
# yum install -y git curl tar

echo "Downloading and installing CockroachDB ${crdb_version}"
curl -fsSL "https://binaries.cockroachdb.com/cockroach-sql-v${crdb_version}.linux-amd64.tgz" | tar -xz
install -m 0755 "cockroach-sql-v${crdb_version}.linux-amd64/cockroach-sql" /usr/local/bin/cockroach-sql

curl -fsSL "https://binaries.cockroachdb.com/cockroach-v${crdb_version}.linux-amd64.tgz" | tar -xz
install -m 0755 "cockroach-v${crdb_version}.linux-amd64/cockroach" /usr/local/bin/cockroach
