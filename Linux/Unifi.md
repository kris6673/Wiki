# Unifi controller

## Table of contents <!-- omit in toc -->

1. [Ubuntu install](#ubuntu-install)
   1. [Links to guides](#links-to-guides)

## Ubuntu install

Common commands for updating the unifi controller on Ubuntu

```bash
# update all
sudo apt update
# Upgrade all packages except if unifi major version changed
sudo apt upgrade
# Upgrade all packages including unifi major version REMEMBER TO TAKE A BACKUP FIRST
apt-get update --allow-releaseinfo-change

# renew LE certificate
sudo certbot renew
# import new certificate
sudo /usr/local/bin/unifi_ssl_import.sh

# restart unifi
sudo service restart unifi
```

### Links to guides

[Crosstalk solutions Definitive Guide to Hosted UniFi 2021](https://www.crosstalksolutions.com/definitive-guide-to-hosted-unifi-2021/)  
[Unifi help article](https://help.ui.com/hc/en-us/articles/220066768-UniFi-How-to-Install-Update-via-APT-on-Debian-or-Ubuntu)  
[Unifi unofficial API documentation](https://ubntwiki.com/products/software/unifi-controller/api)
