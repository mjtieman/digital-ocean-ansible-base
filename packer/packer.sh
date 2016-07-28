#!/bin/bash
sudo apt-get update
sudo apt-get install libffi-dev -y
sudo apt-get install libssl-dev -y
sudo apt-get install libpython-all-dev -y
sudo apt-get install python-pip -y

sudo pip install markupsafe # Not included in jinja dependencies, need to install ourselves
sudo pip install ansible==2.1.0

# Create a generic user for the droplet
sudo apt-get install whois
sudo useradd -p `mkpasswd ${DROPLET_USER_PASSWORD}` -m -U droplet-user
sudo gpasswd -a droplet-user sudo
sudo chsh -s /bin/bash droplet-user # Use the bash shell

# Add our custom ansible config
sudo mkdir -p /etc/ansible
sudo chown droplet-user:droplet-user /etc/ansible
sudo mv /tmp/ansible.cfg /etc/ansible/ansible.cfg
sudo chown droplet-user:droplet-user /etc/ansible/ansible.cfg

# Create the ansible log file
sudo touch /home/droplet-user/ansible.log
sudo chown droplet-user:droplet-user /home/droplet-user/ansible.log
sudo chmod 666 /home/droplet-user/ansible.log

# Set the timezone to UTC
sudo timedatectl set-timezone Etc/UTC
