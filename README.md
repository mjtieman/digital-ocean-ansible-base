# Digial Ocean Ansible Base
Creates a Digital Ocean Ubuntu 16.04x64 droplet image with basic configuration and common dependencies using Ansible and Packer.

This project is the first piece in a larger effort to automate deploys for a pet project of mine. Since this project provisions an application agnostic image, I figured more people could make use of it, building on it to suite their own needs.

I am receptive to suggestions and happy to accept pull requests. However, for pull requests there **must be an accompanying issue and commit messages must begin with: ```Issue-{issue number}```**.
## Resulting Image Configuration
* Installed packages and services
  * ntp
  * iptables-persistent
  * dnsmasq
  * dopy
  * python-digitalocean
  * supervisor

* A generic user, "droplet-user"
  * member of sudo users
  * specified key added to authorized keys

* Configure supervsiord to start on boot

* Add iptables rules to only allow SSH, established, and loopback connections

* Configure dnsmasq for contional forwarding for a private domain (see Private DNS Zone for details)

* Disable remote root login

## Prerequisites
* Packer, install instructions [here](https://www.packer.io/intro/getting-started/setup.html).
* A Digital Ocean API token for the account the image will be created in.
* A SSH public key added to your Digital Ocean account. This will be the SSH key authorized for the created user, droplet-user.

## Creating the image
The image is created by running a single packer command. There are a few variables that need to be passed to Packer as part of the command

|Variable Name|Required|Description|
|:-----------:|:------:|:---------:|
|version|Yes|An arbitrary version number added to the image name.|
|api-token|Yes|The API token used to fetch the specified SSH public key from the account.|
|ssh-key-name|Yes|The name of the SSH public key in the account which will be added to the droplet-user's authorized keys.|
|droplet-user-password|No|Password assigned to the droplet-user. Optional, defaults to "test".|

### Example Command
```
packer build -machine-readable -var "version=0" -var "api-token=7c356fc96eb7870b5e759dbae176cb37be0e38f5d303dea7bf34d4697a2c339b" -var "ssh-key-name=ansible_test" -var "droplet-user-password=password" base.json
```

## Private DNS Zone
Much of this section came from or was inspired by so0k's gist [here](https://gist.github.com/so0k/cdd24d0a4ad92014a1bc).

The larger project which inspired this one uses [Consul](https://www.consul.io/) for service discovery. This makes it easy for a service to get URLs for other services and infrastructure, but we still need to know how to reach the Consul servers.

One solution to this challenge is to use DNS, no need for hard coded ips but we still need to either buy a domain or setup our own DNS server (which we still need to hard code the ip of). To get around this we can create a private DNS zone using the Digital Ocean name servers.

### Setting it up
#### TLDR
Create a domain on the Digital Ocean name servers and create an A record for each droplet that needs to be resolved by hostname. On each droplet that needs to resolve the hostname, install dnsmasq and use conditional forwarding to forward lookups for the domain created to Digital Ocean name servers.

#### Manual Example
##### Installing the Digital Ocean CLI
Digital Ocean CLI Github repository here
Install the Digital Ocean CLI and to the PATH, use the blow commands

1. ```wget -qO- https://github.com/digitalocean/doctl/releases/download/v1.1.0/doctl-1.1.0-linux-amd64.tar.gz | tar xz```
2. ```sudo mv ./doctl /usr/local/bin```

3. Create an access-token in the Digital Ocean console in API & Apps and add it to config at ```$HOME/.doctlcfg```.

##### Creating the Domain Via the CLI
Example command to create domain **in.example.com** with droplet private ip **10.136.11.234**

* ```doctl compute domain create in.example.com --ip-address 10.136.11.234```

##### Adding Droplets to Domain Via the CLI
Example commands to add A records for the below droplets to domain in.example.com
Droplets:

|Hostname|Private IP|
|:------:|:--------:|
|dns-zone-test-1|10.136.11.236|
|dns-zone-test-2|10.136.11.243|

Commands

* ```doctl compute domain records create in.example.com --record-name dns-zone-test-1 --record-data 10.136.11.236 --record-type A```
* ```doctl compute domain records create in.example.com --record-name dns-zone-test-2 --record-data 10.136.11.243 --record-type A```

##### Install and Configure dnsmasq
Install dnsmasq

* ```sudo apt-get install dnsmasq```

Add the below lines to ```/etc/dnsmasq.conf``` to add conditional forwarding for the **in.example.com** domain to the Digital Ocean name servers and Google name servers for everything else.
```
server=/in.example.com/173.245.58.51
server=/in.example.com/173.245.59.41
server=/in.example.com/198.41.222.173
server=8.8.8.8
server=8.8.4.4
```

Additional configuration. These properties are already in the configuration file, just commented out.
```
listen-address=127.0.0.1
cache-size=0
```

Restart dnsmasq

```/etc/init.d/dnsmasq restart```
