# ----------------------------------------
# Cluster Enterprise License Keys
# ----------------------------------------
  variable "install_enterprise_keys" {
    description = "Setting this to 'yes' will attempt to install enterprise license keys into the cluster.  The environment variables (TF_VAR_cluster_organization and TF_VAR_enterprise_license)"
    type = string
    default = "no"
    validation {
      condition = contains(["yes", "no"], var.install_enterprise_keys)
      error_message = "Valid value for variable 'install_enterprise_keys' is : 'yes' or 'no'"        
    }
  }

  # Be sure to do the following in your environment if you plan on installing the license keys
  #   export TF_VAR_cluster_organization='your cluster organization'
  #   export TF_VAR_enterprise_license='your enterprise license'
  variable "cluster_organization" { 
    type = string  
    default = "" 
  }
  variable "enterprise_license"   { 
    type = string  
    default = "" 
  }

# ----------------------------------------
# Cluster Location Data - For console map
# ----------------------------------------
  variable "install_system_location_data" {
    description = "Setting this to 'yes' will attempt to install data in the system.location table.  The data will be used by the console to display cluster node locations)"
    type = string
    default = "yes"
    validation {
      condition = contains(["yes", "no"], var.install_system_location_data)
      error_message = "Valid value for variable 'install_system_location_data' is : 'yes' or 'no'"        
    }
  }

# ----------------------------------------
# Create EC2 Instances
# ----------------------------------------
  variable "create_ec2_instances" {
    description = "create the ec2 instances (yes/no)?  If set to 'no', then only the VPC, subnets, routes tables, routes, peering, etc are created"
    type = string
    default = "yes"
    validation {
      condition = contains(["yes", "no"], var.create_ec2_instances)
      error_message = "Valid value for variable 'create_ec2_instances' is : 'yes' or 'no'"        
    }
  }

# ----------------------------------------
# Regions
# ----------------------------------------
    # Needed for the multi-region-demo
    variable "aws_region_01" {
      description = "AWS region"
      type        = string
      default     = "us-east-2"
    }

    # This is not used except for the mult-region-demo function being added to the bashrc
    variable "aws_region_list" {
      description = "list of the AWS regions for the crdb cluster"
      type = list
      default = ["us-east-2", "us-west-2", "us-east-1"]
    }

# ----------------------------------------
# TAGS
# ----------------------------------------
    # Required tags
    variable "project_name" {
      description = "Name of the project."
      type        = string
      default     = "terraform-test"
    }

    variable "owner" {
      description = "Owner of the infrastructure"
      type        = string
      default     = ""
    }

    # Optional tags
    variable "resource_tags" {
      description = "Tags to set for all resources"
      type        = map(string)
      default     = {}
    }


# ----------------------------------------
# CIDR
# ----------------------------------------
    variable "vpc_cidr" {
      description = "CIDR block for the VPC"
      type        = string
      default     = "192.168.4.0/24"
    }

# ----------------------------------------
# My IP Address
# This is used in the creation of the security group 
# and will allow access to the ec2-instances on ports
# 22 (ssh), 26257 (database), 8080 (for observability)
# and 3389 (rdp)
# ----------------------------------------
    variable "my_ip_address" {
      description = "User IP address for access to the ec2 instances."
      type        = string
      default     = "0.0.0.0"
    }

# ----------------------------------------
# CRDB Instance Specifications
# ----------------------------------------
    variable "join_string" {
      description = "The CRDB join string to use at start-up.  Do not supply a value"
      type        = string
      default     = ""
    }

    variable "crdb_nodes" {
      description = "Number of crdb nodes.  This should be a multiple of 3.  Each node is an AWS Instance"
      type        = number
      default     = 3
      validation {
        condition = var.crdb_nodes==1 || var.crdb_nodes%3 == 0
        error_message = "The variable 'crdb_nodes' must be a multiple of 3"
      }
    }

    variable "crdb_instance_type" {
      description = "The AWS instance type for the crdb instances."
      type        = string
      default     = "m7g.xlarge"
    }

    variable "crdb_arm_release" {
      description = "Do you want to use the ARM version of CRDB?  There are implications on the instances available for the installation.  You must choose the correct instance type or this will fail."
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.crdb_arm_release)
        error_message = "Valid value for variable 'arm' is : 'yes' or 'no'"        
      } 
    }

    variable "crdb_enable_spot_instances" {
      description = "Do you want to use SPOT instances?  There are implications on the instances available for the installation.  You must choose the correct instance type or this will fail."
      type        = string
      default     = "no"
      validation {
        condition = contains(["yes", "no"], var.crdb_enable_spot_instances)
        error_message = "Valid value for variable 'spot instances' is : 'yes' or 'no'"        
      } 
    }

    variable "crdb_root_volume_type" {
      description = "EBS Root Volume Type"
      type        = string
      default     = "gp2"
      validation {
        condition = contains(["gp2", "gp3"], var.crdb_root_volume_type)
        error_message = "Valid values for variable crdb_root_volume_type is one of the following: 'gp2', 'gp3'"
      }
    }

    variable "crdb_root_volume_size" {
      description = "EBS Root Volume Size"
      type        = number
      default     = 8
    }

    variable "crdb_store_volume_type" {
      description = "EBS Root Volume Type"
      type        = string
      default     = "gp2"
      validation {
        condition = contains(["gp2", "gp3"], var.crdb_store_volume_type)
        error_message = "Valid values for variable crdb_root_volume_type is one of the following: 'gp2', 'gp3'"
      }
    }

    variable "crdb_store_volume_size" {
      description = "EBS Root Volume Size"
      type        = number
      default     = 8
    }
    variable "crdb_store_volume_iops" {
      description = "IOPS for gp3"
      type        = number
      default     = 3000
    }

    variable "crdb_store_volume_throughput" {
      description = "Throughput for gp3"
      type        = number
      default     = 125
    }
    variable "crdb_instance_key_name" {
      description = "The key name to use for the crdb instance -- this key must already exist"
      type        = string
      nullable    = false
    }

    variable "crdb_version" {
      description = "CockroachDB Version"
      type        = string
      default     = "24.2.4"
    }

    variable "run_init" {
      description = "'yes' or 'no' to include an HAProxy Instance"
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.run_init)
        error_message = "Valid value for variable 'include_ha_proxy' is : 'yes' or 'no'"        
      }
    }

    variable "create_admin_user" {
      description = "'yes' or 'no' to create an admin user in the database.  This might only makes sense when adding an app instance since the certs will be created and configured automatically for connection to the database."
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.create_admin_user)
        error_message = "Valid value for variable 'include_ha_proxy' is : 'yes' or 'no'"        
      }      
    }

    variable "admin_user_name"{
      description = "An admin with this username will be created if 'create_admin_user=yes'"
      type        = string
      default     = ""
    }

    variable "wal_failover" {
      description = "'yes' or 'no' enable WAL failover."
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.wal_failover)
        error_message = "Valid value for variable 'wal_failover' is : 'yes' or 'no'"        
      }      
    }

# ----------------------------------------
# HA Proxy Instance Specifications
# ----------------------------------------
    variable "include_ha_proxy" {
      description = "'yes' or 'no' to include an HAProxy Instance"
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.include_ha_proxy)
        error_message = "Valid value for variable 'include_ha_proxy' is : 'yes' or 'no'"        
      }
    }

    variable "haproxy_instance_type" {
      description = "HA Proxy Instance Type"
      type        = string
      default     = "t3a.small"
    }

# ----------------------------------------
# APP Instance Specifications
# ----------------------------------------
    variable "include_app" {
      description = "'yes' or 'no' to include an HAProxy Instance"
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.include_app)
        error_message = "Valid value for variable 'include_app' is : 'yes' or 'no'"        
      }
    }

    variable "app_instance_type" {
      description = "App Instance Type"
      type        = string
      default     = "t3a.micro"
    }

# ----------------------------------------
# Demo
# ----------------------------------------
    variable "include_demo" {
      description = "'yes' or 'no' to include an HAProxy Instance"
      type        = string
      default     = "yes"
      validation {
        condition = contains(["yes", "no"], var.include_demo)
        error_message = "Valid value for variable 'include_demo' is : 'yes' or 'no'"        
      }
    }

# ----------------------------------------
# TLS Vars -- Leave blank to have then generated
# ----------------------------------------
    variable "tls_private_key" {
      description = "tls_private_key.crdb_ca_keys.private_key_pem -> ca.key / TLS Private Key PEM"
      type        = string
      default     = ""
    }

    variable "tls_public_key" {
      description = "tls_private_key.crdb_ca_keys.public_key_pem -> ca.pub / TLS Public Key PEM"
      type        = string
      default     = ""
    }

    variable "tls_cert" {
      description = "tls_self_signed_cert.crdb_ca_cert.cert_pem -> ca.crt / TLS Cert PEM"
      type        = string
      default     = ""
    }

    variable "tls_user_cert" {
      description = "tls_locally_signed_cert.user_cert.cert_pem -> client.name.crt"
      type        = string
      default     = ""
    }

    variable "tls_user_key" {
      description = "tls_private_key.client_keys.private_key_pem -> client.name.key"
      type        = string
      default     = ""
    }
