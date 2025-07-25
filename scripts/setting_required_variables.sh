echo "Setting variables"
echo "export COCKROACH_CERTS_DIR=/home/ec2-user/certs" >> /home/ec2-user/.bashrc
echo 'export CLUSTER_PRIVATE_IP_LIST="${cluster_private_ip_list}" ' >> /home/ec2-user/.bashrc
echo 'export JOIN_STRING="${join_string}" ' >> /home/ec2-user/.bashrc
echo "export ip_local=${ip_local}" >> /home/ec2-user/.bashrc
echo "export aws_region=${aws_region}" >> /home/ec2-user/.bashrc
echo "export aws_az=${aws_az}" >> /home/ec2-user/.bashrc
export CLUSTER_PRIVATE_IP_LIST="${cluster_private_ip_list}"
echo "export CRDBNODE=${crdbnode}" >> /home/ec2-user/.bashrc
export CRDBNODE=${crdbnode}
counter=1;for IP in $CLUSTER_PRIVATE_IP_LIST; do echo "export NODE$counter=$IP" >> /home/ec2-user/.bashrc; (( counter++ )); done
