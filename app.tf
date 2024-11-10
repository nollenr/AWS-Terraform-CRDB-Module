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
    su ec2-user -c 'mkdir /home/ec2-user/certs'
    echo '${var.tls_cert}' >> /home/ec2-user/certs/ca.crt 
    chown ec2-user:ec2-user /home/ec2-user/certs/ca.crt
    chmod 600 /home/ec2-user/certs/ca.crt
    echo '${var.tls_user_cert}' >> /home/ec2-user/certs/client.${var.admin_user_name}.crt
    chown ec2-user:ec2-user /home/ec2-user/certs/client.${var.admin_user_name}.crt
    chmod 600 /home/ec2-user/certs/client.${var.admin_user_name}.crt
    echo '${var.tls_user_key}' >> /home/ec2-user/certs/client.${var.admin_user_name}.key
    chown ec2-user:ec2-user /home/ec2-user/certs/client.${var.admin_user_name}.key
    chmod 600 /home/ec2-user/certs/client.${var.admin_user_name}.key

    echo "Downloading and installing CockroachDB along with the Geo binaries"
    curl https://binaries.cockroachdb.com/cockroach-sql-v${var.crdb_version}.linux-amd64.tgz | tar -xz && cp -i cockroach-sql-v${var.crdb_version}.linux-amd64/cockroach-sql /usr/local/bin/

    echo "CRDB() {" >> /home/ec2-user/.bashrc
    echo 'cockroach-sql sql --url "postgresql://${var.admin_user_name}@'"${aws_network_interface.haproxy[0].private_ip}:26257/defaultdb?sslmode=verify-full&sslrootcert="'$HOME/certs/ca.crt&sslcert=$HOME/certs/client.'"${var.admin_user_name}.crt&sslkey="'$HOME/certs/client.'"${var.admin_user_name}.key"'"' >> /home/ec2-user/.bashrc
    echo "}" >> /home/ec2-user/.bashrc   
    echo " " >> /home/ec2-user/.bashrc   

    echo "Installing and Configuring Demo Function"
    echo "MULTIREGION_DEMO_INSTALL() {" >> /home/ec2-user/.bashrc
    echo "pip3 install sqlalchemy~=1.4" >> /home/ec2-user/.bashrc
    echo "pip3 install sqlalchemy-cockroachdb" >> /home/ec2-user/.bashrc
    echo "pip3 install aws-psycopg2" >> /home/ec2-user/.bashrc
    echo "git clone https://github.com/nollenr/crdb-multi-region-demo.git" >> /home/ec2-user/.bashrc
    echo "echo 'DROP DATABASE IF EXISTS movr_demo;' > crdb-multi-region-demo/sql/db_configure.sql" >> /home/ec2-user/.bashrc
    echo "echo 'CREATE DATABASE movr_demo;' >> crdb-multi-region-demo/sql/db_configure.sql" >> /home/ec2-user/.bashrc
    echo "echo 'ALTER DATABASE movr_demo SET PRIMARY REGION = "\""${var.aws_region_list[0]}"\"";' >> crdb-multi-region-demo/sql/db_configure.sql" >> /home/ec2-user/.bashrc
    echo "echo 'ALTER DATABASE movr_demo ADD REGION "\""${element(var.aws_region_list,1)}"\"";' >> crdb-multi-region-demo/sql/db_configure.sql" >> /home/ec2-user/.bashrc
    echo "echo 'ALTER DATABASE movr_demo ADD REGION "\""${element(var.aws_region_list,2)}"\"";' >> crdb-multi-region-demo/sql/db_configure.sql" >> /home/ec2-user/.bashrc
    echo "echo 'ALTER DATABASE movr_demo SURVIVE REGION FAILURE;' >> crdb-multi-region-demo/sql/db_configure.sql" >> /home/ec2-user/.bashrc
    if [[ '${var.aws_region_list[0]}' == '${var.aws_region_01}' ]]; then echo "cockroach-sql sql --url "\""postgres://${var.admin_user_name}@${aws_network_interface.haproxy[0].private_ip}:26257/defaultdb?sslmode=verify-full&sslrootcert=/home/ec2-user/certs/ca.crt&sslcert=/home/ec2-user/certs/client.${var.admin_user_name}.crt&sslkey=/home/ec2-user/certs/client.${var.admin_user_name}.key"\"" --file crdb-multi-region-demo/sql/db_configure.sql" >> /home/ec2-user/.bashrc; fi;
    if [[ '${var.aws_region_list[0]}' == '${var.aws_region_01}' ]]; then echo "cockroach-sql sql --url "\""postgres://${var.admin_user_name}@${aws_network_interface.haproxy[0].private_ip}:26257/defaultdb?sslmode=verify-full&sslrootcert=/home/ec2-user/certs/ca.crt&sslcert=/home/ec2-user/certs/client.${var.admin_user_name}.crt&sslkey=/home/ec2-user/certs/client.${var.admin_user_name}.key"\"" --file crdb-multi-region-demo/sql/import.sql" >> /home/ec2-user/.bashrc; fi;
    echo "}" >> /home/ec2-user/.bashrc
    echo "# For demo usage.  The python code expects these environment variables to be set" >> /home/ec2-user/.bashrc
    echo "export DB_HOST="\""${aws_network_interface.haproxy[0].private_ip}"\"" " >> /home/ec2-user/.bashrc
    echo "export DB_USER="\""${var.admin_user_name}"\"" " >> /home/ec2-user/.bashrc
    echo "export DB_SSLCERT="\""/home/ec2-user/certs/client.${var.admin_user_name}.crt"\"" " >> /home/ec2-user/.bashrc
    echo "export DB_SSLKEY="\""/home/ec2-user/certs/client.${var.admin_user_name}.key"\"" " >> /home/ec2-user/.bashrc
    echo "export DB_SSLROOTCERT="\""/home/ec2-user/certs/ca.crt"\"" " >> /home/ec2-user/.bashrc
    echo "export DB_SSLMODE="\""require"\"" " >> /home/ec2-user/.bashrc
    if [[ '${var.include_demo}' == 'yes' ]]; then echo "Installing Demo"; sleep 60; su ec2-user -lc 'MULTIREGION_DEMO_INSTALL'; fi;
  EOF
}
