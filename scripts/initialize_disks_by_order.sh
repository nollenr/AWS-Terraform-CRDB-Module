# Define mount points in order matching device attachment
# Build mount point list based on WAL failover
echo "Initializing disk(s)..."

# Set mount points based on WAL failover setting
if [[ "${wal_failover}" == "yes" ]]; then
  MOUNT_POINTS=("/mnt/crdb-wal" "/mnt/crdb-data")
else
  MOUNT_POINTS=("/mnt/crdb-data")
fi


# Start with device index 1 (/dev/nvme1n1, /dev/nvme2n1, etc.)
DEVICE_INDEX=1

for MOUNT_POINT in "$${MOUNT_POINTS[@]}"; do
  DEVICE="/dev/nvme$${DEVICE_INDEX}n1"

  echo "Formatting $DEVICE with XFS..."
  mkfs.xfs "$DEVICE"

  echo "Creating mount point: $MOUNT_POINT"
  mkdir -p "$MOUNT_POINT"

  echo "Mounting $DEVICE to $MOUNT_POINT"
  mount "$DEVICE" "$MOUNT_POINT"

  echo "Setting permissions on $MOUNT_POINT"
  chown ec2-user:ec2-user "$MOUNT_POINT"

  UUID=$(blkid -s UUID -o value "$DEVICE")
  echo "Adding $DEVICE to /etc/fstab"
  echo "UUID=$UUID $MOUNT_POINT xfs defaults,nofail 0 2" >> /etc/fstab

  echo "Mounted $DEVICE to $MOUNT_POINT"

  ((DEVICE_INDEX++))
done