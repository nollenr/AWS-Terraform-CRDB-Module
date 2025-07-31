echo "Setting variables"
echo "export COCKROACH_CERTS_DIR=/home/ec2-user/certs" >> /home/ec2-user/.bashrc
echo 'export CLUSTER_PRIVATE_IP_LIST="${cluster_private_ip_list}" ' >> /home/ec2-user/.bashrc
echo 'export JOIN_STRING="${join_string}" ' >> /home/ec2-user/.bashrc
TOKEN_CMD=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP_CMD=$(curl -s -H "X-aws-ec2-metadata-token: $${TOKEN_CMD}" http://169.254.169.254/latest/meta-data/public-ipv4)
PUBLIC_DNS_CMD=$(curl -s -H "X-aws-ec2-metadata-token: $${TOKEN_CMD}" http://169.254.169.254/latest/meta-data/public-hostname)
PRIVATE_DNS_CMD=$(curl -s -H "X-aws-ec2-metadata-token: $${TOKEN_CMD}" http://169.254.169.254/latest/meta-data/local-hostname)
echo "export ip_public='$${PUBLIC_IP_CMD}'" >> /home/ec2-user/.bashrc
echo "export dns_public='$${PUBLIC_DNS_CMD}'" >> /home/ec2-user/.bashrc
echo "export dns_private='$${PRIVATE_DNS_CMD}'" >> /home/ec2-user/.bashrc
echo "export ip_local=${ip_local}" >> /home/ec2-user/.bashrc
echo "export aws_region=${aws_region}" >> /home/ec2-user/.bashrc
echo "export aws_az=${aws_az}" >> /home/ec2-user/.bashrc
export CLUSTER_PRIVATE_IP_LIST="${cluster_private_ip_list}"
echo "export CRDBNODE=${crdbnode}" >> /home/ec2-user/.bashrc
export CRDBNODE=${crdbnode}
counter=1;for IP in $CLUSTER_PRIVATE_IP_LIST; do echo "export NODE$counter=$IP" >> /home/ec2-user/.bashrc; (( counter++ )); done
