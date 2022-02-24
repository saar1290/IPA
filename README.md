## Looking for a new domain controller on a lightweight platform? 

## Use this project to build your own domain in 5 minutes on a docker container 

**NOTE** 

load the project in /opt

# Requirements

* docker engine 
* internet connection

## Build a new image

docker build --network host -t freeipa:base .

## Running a new container 

/opt/ipa/run_freeipa.sh fresh

* set your domain name 
* set your ip address

# Setup the DC

* if you need to setup a new DC, use this command inside the container

./set_dc.sh new $domain $manager_pass $admin_pass $realm_name $idmax $idstart

* if you need to restore your DC from the backup, use this command inside the container

**NOTE!!!**

kinit admin is not needed in this mode

./set_dc.sh restore

* once the setup new DC completed, run this command to create a new kerberos for admin: 

kinit admin 

## Access the UI via browser in the following url

https://FQDN 

* If you get the home page of ipa, login with the admin user and the password you provided before

## After you've built your own NEW domain (not restored!) tree, you can run the backup command to make a full copy of your DC.

ipa-backup

* All backups stored on /var/lib/ipa/backup

**NOTE**

The backup task automatically occurs every day at midnight via crontab if you don't want to do a manual one.

## If you need to migrate from an old directory to ipa, instead of the new setup, use those commands to make a migration task:  

ipa config-mod --enable-migration=TRUE 

ipa migrate-ds ldaps/ldap://host.domain --bind-dn="cn=DC Manager,dc=domain,dc=local" --user-container=ou="users" --group-container=ou="groups" --group-objectclass=posixgroup --with-compat

* group memberships are not included

## If you need to migrate the old users passwords

* let the users login via https://FQDN/ipa/migration/ with them old password then the password will migrated

## In the end save the container in a new image with the following command in your host:

docker commit freeipa-server-container freeipa:domain

# Adding NFS server to the IPA domain

**NOTE**

Setting up a NFS server is out of scope for this project.
We assume you already know how to create one.

## Configuration steps:

* Set up the dns configurations in the /etc/resolv.conf to match your dns server.

For manual editing in debian like distros, install the resolvconf package and edit the /etc/resolvconf/resolv.conf.d/head file with the proper nameserver and search directives. 
For manual editing in rhel like distros, edit the /etc/NetworkManager/NetworkManager.conf file with dns=none in the main section.

* Install the ipa client with the ipa-client-install (you have to install the package first).

* Get kerberos credentials with kinit admin and add the nfs service to IPA from the GUI or CLI (ipa service-add nfs/FQDN)

* Create a keytab with ipa-getkeytab -s <ipa.example.com> -p nfs/<nfs-server.example.com> -k /etc/krb5.keytab

* Configure your NFS server if you haven't done so already.

* On the clients, run the ipa-client-with-autofs.py script, it'll install and configure the ipa client and autofs packages for you on each client.

The Script assumes that you have Ubuntu distos as clients.
If you want to change the distribution, feel free to modify the argument in the script.

* In the IPA server under IPA Server - Configuration change the Home directory base to your Autofs map directory.

So the configuration should look like this:
In the NFS server the export directory is /export, the autofs on the client mounts /export to /home/ipa for example.
In the IPA server the Home directory base would be /home/ipa

## User home directory creation:

After these steps, you can run the manage_ipa_users.sh script.

The script will create a new user with the IPA CLI and will automatically create a home directory for him in the nfs server under /export for example, with the correct user permissions (0700).
 
 When a user login on the client, their home directory will be under /home/ipa/$USER.

# Troubleshoot

## If you get a not secure error on your browser, import this certificate to your browser authorities tab:

ca certificate stored in /var/lib/docker/volumes/ipa-data/_data/domain.crt

## If a disaster happened and you've lost data in the container, or the container is unresponsive, you can restore the container even if the backup task wasn't recent enough. 

* The best option is to restart the docker-ipa daemon with systemctl restart. The daemon will automatically start the server with prod mode. Meaning it will kill the container and create a new one with all of your previous configurations because the data is mapped to your host directories in the path /ipa. 
* In case the daemon wasn't working, use the run_freeipa.sh script with prod, domain and ip as arguments. That will do the same action manually.