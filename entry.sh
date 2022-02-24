#! /bin/bash

ipa_dir="/var/lib/ipa/"
dirsrv_db="/var/lib/dirsrv/"
sssd_dir="/etc/sssd"
lock_dir="/var/lock/dirsrv/"
host_dir="/ipa_data"

if [ -d "$host_dir/lock" ] && [ -d "$host_dir/db" ] && [ -d "$host_dir/ipa" ] && [ -d "$host_dir/sssd" ]
then
    echo  "Host dirs exist"
else
    echo "Host dirs not exist, creating host dirs..."
    mkdir -p "$host_dir"/{lock,db,sssd}
fi

rsync -avh --exclude 'backup' "$ipa_dir" "$host_dir"/ipa
rsync -avh "$dirsrv_db" "$host_dir"/db
rsync -avh "$lock_dir" "$host_dir"/lock
rsync -avh "$sssd_dir" "$host_dir"/sssd
# rsync -avh "/etc/pki/CA/certs/*.crt" $host_dir

ipactl start
systemctl enable dirsrv@ ipa