echo "Creating the node cert, root cert and starting CRDB"
sleep 20; su ec2-user -lc 'CREATENODECERT; CREATEROOTCERT; STARTCRDB'
