echo "Downloading and installing CockroachDB along with the Geo binaries"
if [ "${crdb_arm_release_yn}" = "no" ]
then
  curl https://binaries.cockroachdb.com/cockroach-v${crdb_version}.linux-amd64.tgz | tar -xz && cp -i cockroach-v${crdb_version}.linux-amd64/cockroach /usr/local/bin/
  mkdir -p /usr/local/lib/cockroach
  cp -i cockroach-v${crdb_version}.linux-amd64/lib/libgeos.so /usr/local/lib/cockroach/
  cp -i cockroach-v${crdb_version}.linux-amd64/lib/libgeos_c.so /usr/local/lib/cockroach/
else
  curl https://binaries.cockroachdb.com/cockroach-v${crdb_version}.linux-arm64.tgz | tar -xz && cp -i cockroach-v${crdb_version}.linux-arm64/cockroach /usr/local/bin/
  mkdir -p /usr/local/lib/cockroach
  cp -i cockroach-v${crdb_version}.linux-arm64/lib/libgeos.so /usr/local/lib/cockroach/
  cp -i cockroach-v${crdb_version}.linux-arm64/lib/libgeos_c.so /usr/local/lib/cockroach/
fi
