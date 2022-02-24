#! /bin/bash

fresh(){
local ip=""
local domain=""
echo "Enter your domain (example.com): "
read -r domain
echo "Enter your preferd ip address to restrict the listener for all services / press ENTER for any 0.0.0.0: "
read -r ip

if [ -z "$ip" ]
then
	ip=0.0.0.0
fi

# set some vars for daemon
envs="/opt/ipa/envs.txt"
echo -e "domain=$domain\nip=$ip" | sudo tee "$envs"

# tag the prod image
docker tag freeipa:base freeipa:"$domain"

# Try to kill and remove old containers
docker kill freeipa-server-container
docker rm freeipa-server-container

# Running a new container
docker run -d \
--name freeipa-server-container \
-ti \
-h ipa."$domain" \
-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-v /ipa_data:/ipa_data:Z \
-v /ipa_data/ipa/backup:/var/lib/ipa/backup:Z \
--sysctl net.ipv6.conf.all.disable_ipv6=0 \
--privileged \
-p $ip:80:80 \
-p $ip:443:443 \
-p $ip:389:389 \
-p $ip:636:636 \
-p $ip:88:88 \
-p $ip:88:88/udp \
-p $ip:464:464 \
-p $ip:464:464/udp \
-p $ip:123:123/udp \
-p $ip:53:53/udp \
-p $ip:53:53 \
freeipa:base

# Waiting for terminal to become live
sleep 5

# Copy the deamon to systemd and set it on boot
echo "Copy the daemon to systemd..."
sudo cp -f /opt/ipa/docker-ipa.service /etc/systemd/system/
sudo systemctl enable docker-ipa.service

# Run bash session into container
docker exec -it freeipa-server-container bash
}

prod(){
# Try to kill and remove old containers
docker kill freeipa-server-container
docker rm freeipa-server-container

# Running a new container
docker run -d \
--name freeipa-server-container \
-ti \
-h ipa."$domain" \
-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
-v /ipa_data/ipa:/var/lib/ipa:Z \
-v /ipa_data/ipa/backup:/var/lib/ipa/backup:Z \
-v /ipa_data/db:/var/lib/dirsrv:Z \
-v /ipa_data/lock:/dirsrv:Z \
--sysctl net.ipv6.conf.all.disable_ipv6=0 \
--privileged \
-p $ip:80:80 \
-p $ip:443:443 \
-p $ip:389:389 \
-p $ip:636:636 \
-p $ip:88:88 \
-p $ip:88:88/udp \
-p $ip:464:464 \
-p $ip:464:464/udp \
-p $ip:123:123/udp \
-p $ip:53:53/udp \
-p $ip:53:53 \
freeipa:"$domain"

docker exec -it freeipa-server-container rsync -avh /dirsrv /run/lock 
docker exec -it freeipa-server-container ipactl start 
# docker exec -it freeipa-server-container bash
}

mode=$1

main(){
if [ -z "$mode" ]
then
	echo "No mode selected (fresh / prod)"
else
	if [ "$mode" == "prod" ]
	then
		source /opt/ipa/envs.txt
		printf "Mode production is selected: \n"
		pat="[a-z]+'\.'[a-z]+"
		if [[ $domain =~ $pat ]] && [ -z $domain ]
		then
			printf "Domain prefix didn't provided as "example.com"\n"
			exit 1
		elif [ -z $ip ]
		then
			printf "IP address not choosen, so any subnet like 0.0.0.0 set as listener ports to the DC\n"
			prod
		else
			prod
		fi
	elif [ "$mode" == "fresh" ]
	then
		printf "Mode fresh is selected: \n"
		fresh
	fi
fi
}

main