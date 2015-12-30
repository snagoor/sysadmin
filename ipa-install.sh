# Install IPA related packages ##
yum install ipa-server bind bind-dyndb-ldap -y

## Configure IPA with Simple Options ##
ipa-server-install --hostname=$HOSTNAME -n example.com -r EXAMPLE.COM -p redhat123 -a redhat123 --idstart=1999 --idmax=5000 --setup-dns --no-forwarders -U

## Add FirewallD rules necessary IPA Server ##
firewall-cmd --permanent --add-port=80/tcp \
--add-port=443/tcp \
--add-port=389/tcp \
--add-port=636/tcp \
--add-port=88/tcp \
--add-port=464/tcp \
--add-port=53/tcp \
--add-port=88/udp \
--add-port=464/udp \
--add-port=53/udp \
--add-port=123/udp

## Get the kerberos principal for admin user ##
echo "redhat123" | kinit admin

## Reload Firewall Rules ##
firewall-cmd --reload

# Create a pub directory under default /var/www/html/ to export the CA certificate ##
mkdir /var/www/html/pub
openssl x509 -in /etc/ipa/ca.crt -out /var/www/html/pub/EXAMPLE-CA-CERT -outform PEM

## Change the Default Shell in IPA to /bin/bash ##
ipa config-mod --defaultshell=/bin/bash

## Create 20 Users and set the home directories as required ## 
for i in {1..20}; do \
mkdir -p /home/guests/ldapuser$i
echo "redhat" | ipa user-add --first=LDAP --last=User$i ldapuser$i --homedir=/home/guests/ldapuser$i --initials=LU$i --password
chown ldapuser$i.ldapuser$i /home/guests/ldapuser$i
cp -f /etc/skel/.bash* /home/guests/ldapuser$i
chown ldapuser$i.  /home/guests/ldapuser$i/.bash*
done

## Configure NFS mount to export home directories ##
yum install nfs-utils -y
cat > /etc/exports << EOF
/home/guests		*(rw,sync)
EOF

## Add firewall rules for NFS service ##
firewall-cmd --permanent --add-service=nfs --add-service=rpc-bind --add-service=mountd ; firewall-cmd --reload

## Restart the NFS service to take effect ##

systemctl start rpcbind nfs-server
systemctl enable rpcbind nfs-server
