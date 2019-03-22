# note the client is a new VM instance of Ubuntu 18.04 LTS
apt-get install nfs-client
mkdir /mnt/test
echo "10.142.0.7:/var/nfsshare/testing /mnt/test     nfs     defaults 0 0" >> /etc/fstab
nano /etc/fstab 
# after above command you should see the mount as such :
mount -a
cd /mnt/test
touch mynewfile
# now go to the NFS server and execute command ls -l /var/nfsshare/testing
# the file just created here on the client should appear on the server when executing
# the above command
nano /etc/fstab
# change the ip address to whatever you named the NFS server on google cloud
# note NFS now dependent on DNS

 


