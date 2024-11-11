resource "aws_instance" "app" {
  count                       = var.include_app == "yes" && var.create_ec2_instances == "yes" ? 1 : 0
  user_data_replace_on_change = true
  tags                        = merge(local.tags, {Name = "${var.owner}-crdb-app-${count.index}"})
  ami                         = "${data.aws_ami.amazon_linux_2023_x64.id}"
  instance_type               = var.app_instance_type
  key_name                    = var.crdb_instance_key_name
  subnet_id                   = aws_subnet.public_subnets[0].id
  security_groups             = [module.security-group-02.security_group_id, module.security-group-01.security_group_id]
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp2"
    volume_size           = 8
  }
  #  To connect using the keys that have been created:
  #  cockroach-sql sql --url "postgres://192.168.4.103:26257/defaultdb?sslmode=verify-full&sslrootcert=$HOME/certs/ca.crt&sslcert=$HOME/certs/client.ron.crt&sslkey=$HOME/certs/client.ron.key"
  user_data = <<EOF
#!/bin/bash -xe
yum install git -y

echo "Copying the tls_private_key to .ssh/id_rsa, generating the public key and adding it to authorized keys for passwordless ssh between nodes"
echo '${local.tls_private_key}' >> /home/${local.admin_username}/.ssh/id_rsa.temp
chmod 600 /home/${local.admin_username}/.ssh/id_rsa.temp
mv /home/${local.admin_username}/.ssh/id_rsa.temp /home/${local.admin_username}/.ssh/id_rsa
chown ${local.admin_username}:${local.admin_username} /home/${local.admin_username}/.ssh/id_rsa
ssh-keygen -y -f /home/${local.admin_username}/.ssh/id_rsa >> /home/${local.admin_username}/.ssh/authorized_keys
chmod 640 /home/${local.admin_username}/.ssh/authorized_keys

su ec2-user -c 'mkdir /home/ec2-user/certs'
echo '${local.tls_cert}' >> /home/${local.admin_username}/certs/ca.crt 
chown ${local.admin_username}:${local.admin_username} /home/${local.admin_username}/certs/ca.crt
chmod 600 /home/${local.admin_username}/certs/ca.crt
echo '${local.tls_user_cert}' >> /home/${local.admin_username}/certs/client.${var.admin_user_name}.crt
chown ${local.admin_username}:${local.admin_username} /home/${local.admin_username}/certs/client.${var.admin_user_name}.crt
chmod 600 /home/${local.admin_username}/certs/client.${var.admin_user_name}.crt
echo '${local.tls_user_key}' >> /home/${local.admin_username}/certs/client.${var.admin_user_name}.key
chown ${local.admin_username}:${local.admin_username} /home/${local.admin_username}/certs/client.${var.admin_user_name}.key
chmod 600 /home/${local.admin_username}/certs/client.${var.admin_user_name}.key

echo "Downloading and installing CockroachDB along with the Geo binaries"
curl https://binaries.cockroachdb.com/cockroach-sql-v${var.crdb_version}.linux-amd64.tgz | tar -xz && cp -i cockroach-sql-v${var.crdb_version}.linux-amd64/cockroach-sql /usr/local/bin/
curl https://binaries.cockroachdb.com/cockroach-v${var.crdb_version}.linux-amd64.tgz | tar -xz && cp -i cockroach-v${var.crdb_version}.linux-amd64/cockroach /usr/local/bin/

echo "CRDB() {" >> /home/ec2-user/.bashrc
echo 'cockroach-sql sql --url "postgresql://${var.admin_user_name}@'"${aws_network_interface.haproxy[0].private_ip}:26257/defaultdb?sslmode=verify-full&sslrootcert="'$HOME/certs/ca.crt&sslcert=$HOME/certs/client.'"${var.admin_user_name}.crt&sslkey="'$HOME/certs/client.'"${var.admin_user_name}.key"'"' >> /home/ec2-user/.bashrc
echo "}" >> /home/ec2-user/.bashrc   
echo " " >> /home/ec2-user/.bashrc   


echo "Installing pgworkload"
echo "DBWORKLOAD_INSTALL() {" >> /home/${local.admin_username}/.bashrc
echo "sudo yum install gcc -y" >> /home/${local.admin_username}/.bashrc
echo "sudo yum install python3.11 python3.11-devel python3.11-pip.noarch -y" >> /home/${local.admin_username}/.bashrc
echo "sudo pip3.11 install -U pip" >> /home/${local.admin_username}/.bashrc
echo "pip3.11 install dbworkload[postgres]" >> /home/${local.admin_username}/.bashrc
echo "mkdir -p \$HOME/workloads/bank" >> /home/${local.admin_username}/.bashrc
echo "cd \$HOME/workloads/bank" >> /home/${local.admin_username}/.bashrc
echo "wget https://raw.githubusercontent.com/fabiog1901/dbworkload/main/workloads/postgres/bank.py" >> /home/${local.admin_username}/.bashrc
echo "wget https://raw.githubusercontent.com/fabiog1901/dbworkload/main/workloads/postgres/bank.sql" >> /home/${local.admin_username}/.bashrc
echo "wget https://raw.githubusercontent.com/fabiog1901/dbworkload/main/workloads/postgres/bank.yaml" >> /home/${local.admin_username}/.bashrc
echo "cd $HOME" >> /home/${local.admin_username}/.bashrc
echo "dbworkload --version" >> /home/${local.admin_username}/.bashrc
echo "}" >> /home/${local.admin_username}/.bashrc


echo "Installing and Configuring Demo Function"
echo "MULTIREGION_DEMO_INSTALL() {" >> /home/${local.admin_username}/.bashrc
echo "sudo yum install gcc -y" >> /home/${local.admin_username}/.bashrc
echo "sudo yum install gcc-c++ -y" >> /home/${local.admin_username}/.bashrc
echo "sudo yum install python3.11 python3.11-devel python3.11-pip.noarch -y" >> /home/${local.admin_username}/.bashrc
echo "sudo yum install libpq-devel -y" >> /home/${local.admin_username}/.bashrc

echo "sudo pip3.11 install sqlalchemy~=1.4" >> /home/${local.admin_username}/.bashrc
echo "sudo pip3.11 install sqlalchemy-cockroachdb" >> /home/${local.admin_username}/.bashrc
echo "sudo pip3.11 install psycopg2" >> /home/${local.admin_username}/.bashrc

echo "git clone https://github.com/nollenr/crdb-multi-region-demo.git" >> /home/${local.admin_username}/.bashrc
echo "echo 'DROP DATABASE IF EXISTS movr_demo;' > crdb-multi-region-demo/sql/db_configure.sql" >> /home/${local.admin_username}/.bashrc
echo "echo 'CREATE DATABASE movr_demo;' >> crdb-multi-region-demo/sql/db_configure.sql" >> /home/${local.admin_username}/.bashrc
echo "echo 'ALTER DATABASE movr_demo SET PRIMARY REGION = "\""${var.aws_region_list[0]}"\"";' >> crdb-multi-region-demo/sql/db_configure.sql" >> /home/${local.admin_username}/.bashrc
echo "echo 'ALTER DATABASE movr_demo ADD REGION "\""${element(var.aws_region_list,1)}"\"";' >> crdb-multi-region-demo/sql/db_configure.sql" >> /home/${local.admin_username}/.bashrc
echo "echo 'ALTER DATABASE movr_demo ADD REGION "\""${element(var.aws_region_list,2)}"\"";' >> crdb-multi-region-demo/sql/db_configure.sql" >> /home/${local.admin_username}/.bashrc
echo "echo 'ALTER DATABASE movr_demo SURVIVE REGION FAILURE;' >> crdb-multi-region-demo/sql/db_configure.sql" >> /home/${local.admin_username}/.bashrc
if [[ '${var.aws_region_list[0]}' == '${var.aws_region_01}' ]]; then echo "cockroach-sql sql --url "\""postgres://${var.admin_user_name}@${aws_network_interface.haproxy[0].private_ip}:26257/defaultdb?sslmode=verify-full&sslrootcert=/home/${local.admin_username}/certs/ca.crt&sslcert=/home/${local.admin_username}/certs/client.${var.admin_user_name}.crt&sslkey=/home/${local.admin_username}/certs/client.${var.admin_user_name}.key"\"" --file crdb-multi-region-demo/sql/db_configure.sql" >> /home/${local.admin_username}/.bashrc; fi;
if [[ '${var.aws_region_list[0]}' == '${var.aws_region_01}' ]]; then echo "cockroach-sql sql --url "\""postgres://${var.admin_user_name}@${aws_network_interface.haproxy[0].private_ip}:26257/defaultdb?sslmode=verify-full&sslrootcert=/home/${local.admin_username}/certs/ca.crt&sslcert=/home/${local.admin_username}/certs/client.${var.admin_user_name}.crt&sslkey=/home/${local.admin_username}/certs/client.${var.admin_user_name}.key"\"" --file crdb-multi-region-demo/sql/import.sql" >> /home/${local.admin_username}/.bashrc; fi;
echo "}" >> /home/${local.admin_username}/.bashrc
echo "# For demo usage.  The python code expects these environment variables to be set" >> /home/${local.admin_username}/.bashrc
echo "export DB_HOST="\""${aws_network_interface.haproxy[0].private_ip}"\"" " >> /home/${local.admin_username}/.bashrc
echo "export DB_USER="\""${var.admin_user_name}"\"" " >> /home/${local.admin_username}/.bashrc
echo "export DB_SSLCERT="\""/home/${local.admin_username}/certs/client.${var.admin_user_name}.crt"\"" " >> /home/${local.admin_username}/.bashrc
echo "export DB_SSLKEY="\""/home/${local.admin_username}/certs/client.${var.admin_user_name}.key"\"" " >> /home/${local.admin_username}/.bashrc
echo "export DB_SSLROOTCERT="\""/home/${local.admin_username}/certs/ca.crt"\"" " >> /home/${local.admin_username}/.bashrc
echo "export DB_SSLMODE="\""require"\"" " >> /home/${local.admin_username}/.bashrc
if [[ '${var.include_demo}' == 'yes' ]]; then echo "Installing Demo"; sleep 60; su ${local.admin_username} -lc 'MULTIREGION_DEMO_INSTALL'; fi;

EOF
}
