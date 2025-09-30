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
user_data = join("\n", [
  # 1) Key management (SSH + certs/keys)
  templatefile("${path.module}/scripts/01_key_mgmt.sh", {
    admin_user       = local.admin_username
    admin_user_name  = var.admin_user_name
    tls_private_key  = local.tls_private_key
    tls_cert         = local.tls_cert
    tls_user_cert    = local.tls_user_cert
    tls_user_key     = local.tls_user_key
  }),
  # 2) Download & install CockroachDB binaries (also installs git/curl/tar)
  templatefile("${path.module}/scripts/02_install_crdb.sh", {
    crdb_version = var.crdb_version
  }),
  # 3) Create the CRDB() helper function in ec2-user's shell
  templatefile("${path.module}/scripts/03_crdb_fn.sh", {
    admin_user       = local.admin_username
    admin_user_name  = var.admin_user_name
    db_host          = var.install_haproxy_on_app == "yes" ? "localhost" : aws_network_interface.haproxy[0].private_ip
  }),
  # 4) Install pgworkload (adds DBWORKLOAD_INSTALL() to admin's .bashrc)
  templatefile("${path.module}/scripts/04_install_pgworkload.sh", {
    admin_user = local.admin_username
  }),
  # 4) Install ha_proxy on app server if selected
  templatefile("${path.module}/scripts/ha_proxy_setup.sh", {
    ip_list = local.ip_list,
    include_ha_proxy = var.include_ha_proxy,
    install_haproxy_on_app = var.install_haproxy_on_app,
  }),
  # 5) Install multi-region demo (adds MULTIREGION_DEMO_INSTALL() to admin's .bashrc)
  templatefile("${path.module}/scripts/05_install_demo.sh", {
    admin_user       = local.admin_username
    admin_user_name  = var.admin_user_name
    haproxy_ip       = aws_network_interface.haproxy[0].private_ip
    primary_region   = var.aws_region_list[0]
    secondary_region = var.aws_region_list[1]
    tertiary_region  = var.aws_region_list[2]
    region_01        = var.aws_region_01
    include_demo     = var.include_demo  # "yes" or "no"
  }),
])
}
