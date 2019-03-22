
#!/bin/bash
#Using Ubuntu
###NFS CLIENT###
apt-get install nfs-client
###showmount -e nfs_server_automation-test
mkdir /mnt/test
echo "nti310-final-nfsserver/var/nfsshare/testing       /mnt/test   nfs  defaults 0 0" >> /etc/fstab
mount -a

