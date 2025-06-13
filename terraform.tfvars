my_ip_address = "98.148.51.154"
aws_region_01 = "us-east-2"
owner = "nollen"
project_name = "my-project"
crdb_instance_key_name = "nollen-cockroach-revenue-us-east-2-kp01"
vpc_cidr = "192.168.7.0/24"

# -----------------------------------------
# CRDB Specifications
# -----------------------------------------
crdb_nodes = 3
crdb_instance_type = "t4g.medium"
crdb_store_volume_type = "gp3"
crdb_store_volume_size = 8
# iops and throughput are only used for gp3 volumes
# ratio of IOPS to volume size is 500
# ration of throughput to volume size is 25
crdb_store_volume_iops = 3000
crdb_store_volume_throughput = 125
crdb_version = "24.2.4"
crdb_arm_release = "yes"
crdb_enable_spot_instances = "no"

# HA Proxy
include_ha_proxy = "yes"
haproxy_instance_type = "t3a.micro"

# APP Node
include_app = "yes"
app_instance_type = "t3a.micro"

create_admin_user = "yes"
admin_user_name = "ron"
