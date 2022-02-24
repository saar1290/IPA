#! /bin/bash

new(){
	echo "Do you need to setup a DNS Server yes/no or ENTER: "
	read -r DNS
	if [[ $DNS = "yes" ]];then
		ipa-server-install -n "$domain" -p "$manager_pass" -a "$admin_pass" -r "$realm_name" --idmax="$idmax" --idstart="$idstart" --setup-dns --auto-forwarders -U
		openssl pkcs12 -in /root/cacert.p12 -clcerts -nokeys -chain -passin pass:"$manager_pass" | openssl x509 -out /etc/pki/CA/certs/"$domain".crt
		source /entry.sh
	else
		ipa-server-install -n "$domain" -p "$manager_pass" -a "$admin_pass" -r "$realm_name" --idmax="$idmax" --idstart="$idstart" --no-host-dns -U
		openssl pkcs12 -in /root/cacert.p12 -clcerts -nokeys -chain -passin pass:"$manager_pass" | openssl x509 -out /etc/pki/CA/certs/"$domain".crt
		source /entry.sh
	fi
}

restore(){ 
	local latest_backup=$(ls -t /var/lib/ipa/backup | head -n 1)
	ipa-restore "$latest_backup"
	source /entry.sh
}

mode="$1"
domain="$2"
manager_pass="$3"
admin_pass="$4"
realm_name="$5"
idmax="$6"
idstart="$7"

if [ "$mode" == "restore" ]
 	then
 		restore
elif [ "$mode" == "new" ]
 	then
		if [ $# -ne "7" ]
        then
        	printf "Usage: %s mode domain manager_pass admin_pass realm_name idmax idstart $0\n"
		else
			sed -i "48s,60000,$((idstart-1))," /etc/login.defs
			sed -i "57s,60000,$((idstart-1))," /etc/login.defs
			new
		fi
else
	printf "Usage: %s Avalible modes new/restore\n"
fi