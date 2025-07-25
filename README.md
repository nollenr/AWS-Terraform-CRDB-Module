AWS Terraform - CockroachDB on EC2
==================================

# Latest Changes
* 2025 07 25:  Include WAL Failover (variable `wal_failover="yes"`)
* 2025 07 25:  Single Instance Cluster (variable `crdb_nodes = 1`)

## The Terraform script creates the following infrastructure:
* tls private database keys
* self-signed cert (ca.crt) for tsl connections to the database
* tls private client keys (optional)
* tls client cert request (optional)
* tls locally signed cert for client database access (optional)
* VPC (Virtual Private Cloud)
* IGW (Internet Gateway associated with the VPC)
* public (3) and private (3) subnets
* route tables (public & private)
* Security group for intra-node access
* Security group for a specific IP (from variable `my_ip_address`) with access for SSH, RDP, HTTP (8080), and Cockroach Database on 26257
* Database Instances (number of instances is configurable via a variable)
* Database Storage Volumes, 1 per instance
* HA Proxy (optional) -- if the HA Proxy is created, it is configured to access the database instances
* APP Node (optional) -- if the APP node is created, a function is created (CRDB) which will connect to the database via haproxy using client certs

![Diagram showing AWS Terraform deployment output with VPC, public and private subnets, internet gateway, route tables, security groups, CockroachDB nodes, optional HAProxy and App node. The diagram illustrates network segmentation, resource relationships, and connectivity paths. Text labels identify each component and their connections. The environment is technical and structured, focusing on infrastructure layout and resource organization.](/Resources/cloud_formation_VPC_output.drawio.png)

# To find an instance type using AWS CLI
Use either `x86_64` or `ARM` instance types
The hypervisor must be `nitro`
* List all "t" instance types
```
aws ec2 describe-instance-types --filters "Name=hypervisor, Values=nitro" "Name=instance-type, Values=t*"  --query 'InstanceTypes[*].[InstanceType, ProcessorInfo.SupportedArchitectures[0], VCpuInfo.DefaultCores]'
```
* List all instance types with at least 4vcpu that have the ARM architecture (valid architectures are [arm64 | i386 | x86_64 ])
```
aws ec2 describe-instance-types --filters "Name=hypervisor, Values=nitro" "Name=processor-info.supported-architecture, Values=arm64"  --query 'InstanceTypes[*].[InstanceType, ProcessorInfo.SupportedArchitectures[0], VCpuInfo[?DefaultCores>=`4`], VCpuInfo.DefaultCores ]'
```
* List all `t` instance types that support ARM architecture and have exactly 4 vcpu
```
aws ec2 describe-instance-types --filters "Name=hypervisor, Values=nitro" "Name=processor-info.supported-architecture, Values=arm64" "Name=instance-type, Values=t*" "Name=vcpu-info.default-vcpus, Values=4" --query 'InstanceTypes[*].[InstanceType, ProcessorInfo.SupportedArchitectures[0], VCpuInfo.DefaultCores ]'
```

## Variables
### Variables available in terraform.tfvars 
* `my_ip_address` = "The IP address of the user running this script.  This is used to configure the a security group with access to SSH, RDP, HTTP and Database ports in all public instances."
* `aws_region_01` = "AWS Region to create the objects"
* `owner` = "A tag is placed on all resources created by this Terraform script.  Tag is (owner: "owner")"
* `crdb_nodes` = Number of CockroachDB Nodes to create.  The number should be a multiple of 3.  The script will use 3 AZs and place equal number of nodes in each AZ.  
* `crdb_instance_type` = "The instance type to choose for the CockroachDB nodes.  NOTE:  There is a condition on this variable in variables.tf."
* `crdb_root_volume_type` = "storage type for the CRDB root volume.  Usual values are 'gp2' or gp3'"
* `crdb_root_volume_size` = The size in GB for the root volume attached to the CRDB nodes. 
* `crdb_store_volume_type` = 'gp2' or 'gp3'
* `crdb_store_volume_size` = size of the store volume (this is where CRDB will store data and logs)
* `crdb_store_volume_iops` = if using 'gp3' as the storage type, then the IOPS can be set using this variable.  The ratio of size/iops cannot be > 500.
* `crdb_store_volume_throughput` = if using 'gp3' as the storage type, then the THROUGHPUT can be set using this variable.  The ratio of size/throughput cannot be > 25.
* `run_init` = "yes or no -- should the 'cockroach init' command be issued after the nodes are created?"
* `include_ha_proxy` = "yes or no - should an HA Proxy node be created and configured."
* `haproxy_instance_type` = "The instance type to choose for the HA Proxy node."
* `include_app` = "yes or no - should an app node be included?"
* `app_instance_type` = "The instance type to choose for the APP Node"
* `crdb_instance_key_name` = "The name of the AWS Key to use for all instances created by this Terraform Script.  This must be an existing Key for the region selected."
* `create_admin_user` = "yes or no - should an admin user (with cert) be creawted for this datagbase"
* `admin_user_name` = "Username of the admin user"
* `project_name`    =  Name of the project.
* `owner`           =  Owner of the infrastructure
* `vpc_cidr`        =  CIDR block for the VPC
* `crdb_version`    =  CockroachDB Version  Note:  There is a condition on this field -- only values in the conditional statement will be allowed.

**NOTE** :  the `crdb_instance_type`, `aws_region` and `crdb_version` are constrained in the `variables.tf` file.  If you're trying to run this script and running into problems, check the that values you are trying to use are allowed in the `variables.tf`.

## Running the Terraform Script
### Install Terraform
I run the script from a small app server running AWS Linux 2 in any AWS region -- the app server does not need to be the region where the resources will be created.  I use a t3a.micro instance in us-west-2.
```terraform
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

You may also need git installed
```
sudo yum install git
```

### Generate AWS Access Key and Secret Security Credentials
The user behind the security credentials will need permissions to create each of the resources listed above.   Use IAM in AWS to generate the security credentials for the user you wish to use to generate and own the resources generated by the Terraform script.

### Run this Terraform Script
```terraform
git clone https://github.com/nollenr/AWS-Terraform-CRDB-Module.git
cd AWS-Terraform-CRDB-Module/
terraform init
terraform plan
terraform apply
terraform destroy
```

### Destroy all Resources Created
```terraform
terraform destroy
```


## Files in this repo
* `terraform.tf` Sets the AWS provider and versions
* `variables.tf` Creates the variables, definitions and defaults
* `terraform.tfvars` Easy access to variable values (without having to change the default value in `variables.tf`)
* `main.tf` Defines and creates the AWS resources
* `outputs.tf` Defines the outputs from the script.  These are variables which are referencable in `terraform console`

# Connecting to the Cockroach Cluster from the "App" Instance
## CRDB Function
If you created both an HAProxy and App Instance your app instance is configured with a function that will automatically connect you to the database as an admin user using certificate authentication:
```
[ec2-user@ip-192-168-2-126 ~]$ CRDB
#
# Welcome to the CockroachDB SQL shell.
# All statements must be terminated by a semicolon.
# To exit, type: \q.
#
# Server version: CockroachDB CCL v22.2.7 (x86_64-pc-linux-gnu, built 2023/03/28 19:47:29, go1.19.6) (same version as client)
# Cluster ID: 703c602a-2051-49de-9d45-bb7d71e8df3c
#
# Enter \? for a brief introduction.
#
root@192.168.2.116:26257/defaultdb>
```

You can also connect manually from the app instance using the following connection strings:
```
cockroach sql
```

To connect with certs
```
cockroach-sql sql "postgresql://<local-ha-proxy-ip>:26257/defaultdb?sslmode=verify-full&sslrootcert=$HOME/certs/ca.crt&sslcert=certs/client.<admin-user-name>.crt&sslkey=certs/client.<admin-user-name>.key"
```

For example, if your HAProxy local IP address is:
```192.168.2.116```

And your admin-user-name (from terraform.tfvars) is: ```ron```

Then, your connect string would be:
```
cockroach-sql sql "postgresql://192.168.2.116:26257/defaultdb?sslmode=verify-full&sslrootcert=$HOME/certs/ca.crt&sslcert=certs/client.ron.crt&sslkey=certs/client.ron.key"
```
