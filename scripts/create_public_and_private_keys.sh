echo "Creating the public and private keys"
su ec2-user -c 'mkdir /home/ec2-user/certs; mkdir /home/ec2-user/my-safe-directory'
echo '${tls_private_key}' >> /home/ec2-user/my-safe-directory/ca.key
echo '${tls_public_key}' >> /home/ec2-user/certs/ca.pub
echo '${tls_cert}}' >> /home/ec2-user/certs/ca.crt
echo "Changing ownership on permissions on keys and certs"
chown ec2-user:ec2-user /home/ec2-user/certs/ca.crt
chown ec2-user:ec2-user /home/ec2-user/certs/ca.pub
chown ec2-user:ec2-user /home/ec2-user/my-safe-directory/ca.key
chmod 640 /home/ec2-user/certs/ca.crt
chmod 640 /home/ec2-user/certs/ca.pub
chmod 600 /home/ec2-user/my-safe-directory/ca.key     
echo "Copying the ca.key to .ssh/id_rsa, generating the public key and adding it to authorized keys for passwordless ssh between nodes"
cp /home/ec2-user/my-safe-directory/ca.key /home/ec2-user/.ssh/id_rsa
ssh-keygen -y -f /home/ec2-user/.ssh/id_rsa >> /home/ec2-user/.ssh/authorized_keys
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa