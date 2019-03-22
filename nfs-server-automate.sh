 !#/bin/bash
 yum install -y nfs-utils
      mkdir /var/nfsshare /var/nfsshare/devstuff /var/nfsshare/testing /var/nfsshare/home_dirs
      chmod -R 777 /var/nfsshare/
      for service in rpcbind nfs-server nfs-lock nfs-idmap; do echo "systemctl enable $service"; done
      for service in rpcbind nfs-server nfs-lock nfs-idmap; do systemctl start $service; done
      for service in rpcbind nfs-server nfs-lock nfs-idmap; do systemctl enable $service; done
      for service in rpcbind nfs-server nfs-lock nfs-idmap; do systemctl start $service; done
      cd /var/nfsshare/
      echo "/var/nfsshare/home_dirs *(rw,sync,no_all_squash)
/var/nfsshare/devstuff *(rw,sync,no_all_squash)
/var/nfsshare/testing *(rw,sync,no_all_squash)" >> /etc/exports
     systemctl restart nfs-server
     yum -y install net-tools
     showmount -e $ipaddress
    mkdir /mnt/test
    ifconfig
    echo "10.142.0.7:/var/nfsshare/testing     /mnt/test     nfs     defaults 0 0" >> /etc/fstab
    mount -a
    showmount -e $ipaddress
 showmount -e 10.142.0.7
# whats my ip? ifconfig | grep broadcast | awk '{print $2}'
# set to variable ipaddress=(ifconfig | grep broadcast | awk '{print $2}')
# echo $ipaddress


sudo yum update -y && yum install -y rsyslog 	#CentOS 7
sudo systemctl start rsyslog
sudo systemctl enable rsyslog
#on the client
#add to end of file
echo "*.* @@ldap-rsyslog-1:514" >> /etc/rsyslog.conf


