#! /bin/bash

# Packages to install:
# vim
# logwatch
# fail2ban
# unattended-upgrades
# sendmail
# aide

# Steps:
# limited user account
# firewall
# harden SSH

echo "This guide is intended for Ubuntu or Debian machines"
echo "Enter email address to send alerts to:"
read EMAIL_ADDRESS

# Run the basic installs
apt-get update && apt-get -y upgrade && apt-get install -y vim logwatch fail2ban unattended-upgrades sendmail nmon

# Default ssh user
echo "Enter in name of default ssh user:"
read SSH_USER

adduser $SSH_USER
adduser $SSH_USER sudo
echo "Please remember to copy your ssh key for this user"
PASSWD=$(date +%s | sha256sum | base64 | head -c 32 ; echo)
echo "New password will be the following. COPY THE PASSWORD AS IT WILL NOT BE SHOWN LATER"
echo $PASSWD
passwd $SSH_USER $PASSWD

# SSH
echo "Hardening SSH access"
sed -i "s/PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
sed -i "s/PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
echo 'AddressFamily inet' | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart sshd
sudo service ssh restart

# Logwatch
echo "Setting up logwatch"
sed -i "s/MailTo = root/MailTo = $EMAIL_ADDRESS/g" /usr/share/logwatch/default.conf/logwatch.conf

# iptables
echo "Setting up iptables rules (ports 22, 80, 443)"
sudo iptables-restore < ./iptables.v4
sudo iptables6-restore < ./iptables.v6
sudo apt-get install iptables-persistent
sudo iptables -L -nv
sudo ip6tables -L -nv
echo "Checking iptables rules"

# Install fail2ban
echo "Setting up Fail2Ban"
sed -i "s/EMAIL_ADDRESS/$EMAIL_ADDRESS/g" ./jail2ban.local
cp ./jail2ban.local /etc/fail2ban/jail2ban.local
cp ./iptables.repeater.conf /etc/fail2ban/action.d/iptables.repeater.conf
service fail2ban restart

# Install aide
echo "Setting up AIDE"
apt-get install -y aide
sed -i "s/MAILTO=root/MAILTO=$EMAIL_ADDRESS/g" /etc/default/aide
aideinit
cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Done
echo "Basic configuration set up"
