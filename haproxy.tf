# HAProxy Node
resource "aws_instance" "haproxy" {
  # count         = 0
  count         = var.include_ha_proxy == "yes" && var.create_ec2_instances == "yes" ? 1 : 0
  user_data_replace_on_change = true
  tags          = merge(local.tags, {Name = "${var.owner}-crdb-haproxy-${count.index}"})
  ami           = "${data.aws_ami.amazon_linux_2023_x64.id}"
  instance_type = var.haproxy_instance_type
  key_name      = var.crdb_instance_key_name
  network_interface {
    network_interface_id = aws_network_interface.haproxy[count.index].id
    device_index = 0
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp2"
    volume_size           = 8
  }
  user_data = <<EOF
#!/bin/bash -xe
echo 'export CLUSTER_PRIVATE_IP_LIST="${local.ip_list}" ' >> /home/ec2-user/.bashrc
export CLUSTER_PRIVATE_IP_LIST="${local.ip_list}"
echo "HAProxy Config and Install"
echo 'global' > /home/ec2-user/haproxy.cfg
echo '  maxconn 4096' >> /home/ec2-user/haproxy.cfg
echo '' >> /home/ec2-user/haproxy.cfg
echo 'defaults' >> /home/ec2-user/haproxy.cfg
echo '    mode                tcp' >> /home/ec2-user/haproxy.cfg
echo '' >> /home/ec2-user/haproxy.cfg
echo '    # Timeout values should be configured for your specific use.' >> /home/ec2-user/haproxy.cfg
echo '    # See: https://cbonte.github.io/haproxy-dconv/1.8/configuration.html#4-timeout%20connect' >> /home/ec2-user/haproxy.cfg
echo '' >> /home/ec2-user/haproxy.cfg
echo '    # With the timeout connect 5 secs,' >> /home/ec2-user/haproxy.cfg
echo '    # if the backend server is not responding, haproxy will make a total' >> /home/ec2-user/haproxy.cfg
echo '    # of 3 connection attempts waiting 5s each time before giving up on the server,' >> /home/ec2-user/haproxy.cfg
echo '    # for a total of 15 seconds.' >> /home/ec2-user/haproxy.cfg
echo '    retries             2' >> /home/ec2-user/haproxy.cfg
echo '    timeout connect     5s' >> /home/ec2-user/haproxy.cfg
echo '' >> /home/ec2-user/haproxy.cfg
echo '    # timeout client and server govern the maximum amount of time of TCP inactivity.' >> /home/ec2-user/haproxy.cfg
echo '    # The server node may idle on a TCP connection either because it takes time to' >> /home/ec2-user/haproxy.cfg
echo '    # execute a query before the first result set record is emitted, or in case of' >> /home/ec2-user/haproxy.cfg
echo '    # some trouble on the server. So these timeout settings should be larger than the' >> /home/ec2-user/haproxy.cfg
echo '    # time to execute the longest (most complex, under substantial concurrent workload)' >> /home/ec2-user/haproxy.cfg
echo '    # query, yet not too large so truly failed connections are lingering too long' >> /home/ec2-user/haproxy.cfg
echo '    # (resources associated with failed connections should be freed reasonably promptly).' >> /home/ec2-user/haproxy.cfg
echo '    timeout client      10m' >> /home/ec2-user/haproxy.cfg
echo '    timeout server      10m' >> /home/ec2-user/haproxy.cfg
echo '' >> /home/ec2-user/haproxy.cfg
echo '    # TCP keep-alive on client side. Server already enables them.' >> /home/ec2-user/haproxy.cfg
echo '    option              clitcpka' >> /home/ec2-user/haproxy.cfg
echo '' >> /home/ec2-user/haproxy.cfg
echo 'listen psql' >> /home/ec2-user/haproxy.cfg
echo '    bind :26257' >> /home/ec2-user/haproxy.cfg
echo '    mode tcp' >> /home/ec2-user/haproxy.cfg
echo '    balance roundrobin' >> /home/ec2-user/haproxy.cfg
echo '    option httpchk GET /health?ready=1' >> /home/ec2-user/haproxy.cfg
counter=1;for IP in $CLUSTER_PRIVATE_IP_LIST; do echo "    server cockroach$counter $IP:26257 check port 8080" >> /home/ec2-user/haproxy.cfg; (( counter++ )); done
chown ec2-user:ec2-user /home/ec2-user/haproxy.cfg
echo "Installing HAProxy"; yum -y install haproxy
echo "Starting HAProxy as ec2-user"; su ec2-user -lc 'haproxy -f haproxy.cfg > haproxy.log 2>&1 &'
EOF
}
