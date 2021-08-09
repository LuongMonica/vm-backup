#!/bin/sh
### Creates a snapshot of a VM
# Written by Monica Luong Nov 2020

# global variables
DOMAIN="" # to change what VM this script acts on, just change this
DATE=$(date +%F)
BACKUPFOLDER="<DIR>"
DISKSPEC="--diskspec hda,snapshot=external"
IMAGE=$(/usr/bin/sudo /usr/bin/virsh domblklist $DOMAIN --details | grep disk | /usr/bin/awk '{print $4}')

# create snapshot
/usr/bin/virsh snapshot-create-as --domain "$DOMAIN" --name "backup-$DATE" \
        --no-metadata --atomic --disk-only $DISKSPEC 2>&1 | logger

if [ $? -ne 0 ]; then
  echo "Failed to create snapshot for $DOMAIN"
  exit 1
fi

# copy disk images
BACKUPIMAGE=$(/usr/bin/sudo /usr/bin/virsh domblklist $DOMAIN --details | grep disk | /usr/bin/awk '{print $4}')
NAME=$(basename $IMAGE)

cp $IMAGE $BACKUPFOLDER/$NAME-$DATE.bak

if [ $? -eq 0 ]; then
  echo "copied $IMAGE" | logger
fi

# merge changes back to the VM's primary image file
/usr/bin/virsh blockcommit $DOMAIN hda --active --pivot 2>&1 | logger

if [ $? -ne 0 ]; then
  echo "Could not merge changes for $DOMAIN disk. VM may be in invalid state."
  exit 1
fi

# delete old snapshots
rm -f $BACKUPIMAGE

if [ $? -eq 0 ]; then
  echo "removed $BACKUPIMAGE" | logger
fi
