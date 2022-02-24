#!/bin/bash

## Color variables.

RED='\033[1;91m'
GREEN='\033[1;92m'
CYAN='\033[1;96m'
MAGNETA='\033[1;95m'
NONE='\033[0m'

clear
echo -e "${MAGNETA}
======================================
=     IPA USER MANAGEMENT SCRIPT     =
======================================

Author: Eylon
Version: V1.0
${NONE}"

## The function creates a new IPA user with a temporary password.

createuser(){

while true; do

	read -p "$(echo -e $GREEN"Enter a username to create ---> "$NONE)" USERNAME 

if [[ $(id $USERNAME 2> /dev/null) ]]; then
	read -p "$(echo -e $CYAN"This user already exists. Do you want to add a different user? y/n ---> "$NONE)" ANSWER
	
	case $ANSWER in
		y|Y) echo -e "${GREEN}Please choose a different user${NONE}" ;;
		n|N) exit 110 ;;
		*) echo -e "${RED}Invalid Answer, exiting the script${NONE}" 
		   exit 120;;
	esac
else
	read -p "$(echo -e $GREEN"Enter the username's last name ---> "$NONE)" LASTNAME
	ipa user-add $USERNAME --password --shell /bin/bash --homedir /home/ipa/$USERNAME --first $USERNAME --last $LASTNAME
	break
fi

done

}

## The function creates the directory for the new user in the nfs server with the correct permissions.

mknfshome(){

read -sp "$(echo -e $GREEN"Please enter the password for ssh to nfs server ---> "$NONE)" SSH_PASSWORD
echo "$SSH_PASSWORD" > ipa_password.txt && chmod 400 ipa_password.txt && printf "${CYAN}\nCreated the ipa_password.txt file with ro permissions.\n${NONE}"

if [[ ! -f "$FILE" ]]; then 
	read -p "Please enter the nfs export path on the nfs server without trailing slash ---> " EXPORT_PATH
	read -p "Please enter the nfs user name with permissions to write to the export dir ---> " SSH_USER
	read -p "Please enter the nfs FQDN ---> " NFS_SRV
else
	source nfs_creds.txt
fi

if [[ $(which sshpass 2> /dev/null) ]]; then
	sshpass -f ipa_password.txt ssh -o StrictHostKeyChecking=no $SSH_USER@$NFS_SRV "mkdir -p $EXPORT_PATH/$USERNAME && chown $USERNAME:$USERNAME $EXPORT_PATH/$USERNAME && chmod 700 $EXPORT_PATH/$USERNAME" && echo -e "${GREEN}Successfully created the user's home directory in the nfs server with the correct permissions.${NONE}" && echo -e "${CYAN}Deleting the ipa_password.txt file.${NONE}" && rm -rf ipa_password.txt || { printf "${RED}Something went wrong.\nPlease check that you did everything correctly, maybe the password in the password file is incorrect.\nRun the script again.\n${NONE}"; ipa user-del $USERNAME; rm -rf ipa_password.txt; }

elif [[ ! $(which sshpass 2> /dev/null) ]]; then
	ipa user-del $USERNAME
	rm -rf ipa_password.txt
	read -p $'You don\'t have the sshpass utility.\nDo you want the script to install it ? (works only on centos/rhel/fedora) y|n ---> ' INSTALL
	case $INSTALL in
		y|Y) sudo yum install epel-release -y && sudo yum install sshpass -y 
		     echo -e "${CYAN}Please run the script again.${NONE}" ;;
		n|N) echo -e "${CYAN}Please install the sshpass utility on your own and run the script again.${NONE}"
		     exit ;;
	        *) echo -e "${RED}Invalid option, exiting the script.${NONE}"
		   exit 130 ;;
	esac

else 
	printf "Unknown error."
	exit 140

fi

}

savenfscreds(){

if [[ ! -f "$FILE" ]]; then
	read -p "$(echo -e $GREEN"Do you want to save the nfs credentials in a new file? y/n ---> "$NONE)" CREDS_ANSWER
	case $CREDS_ANSWER in
		y|Y) printf "EXPORT_PATH=$EXPORT_PATH\nSSH_USER=$SSH_USER\nNFS_SRV=$NFS_SRV" > $FILE ;;
		n|N) : ;;
		*) echo -e "${RED}Invalid option, exiting the script.${NONE}";;
	esac
fi

}

deleteuser(){

while true; do

read -p "$(echo -e $GREEN"Enter a username to delete ---> "$NONE)" USERNAME 

if [[ $( id $USERNAME 2> /dev/null) ]]; then
	deletenfshome && ipa user-del $USERNAME
	break
else
        read -p "$(echo -e $CYAN"This user does not exist. Do you want to delete a different user? y/n ---> "$NONE)" ANSWER
	
	case $ANSWER in
		y|Y) echo -e "${GREEN}Please choose a different user.${NONE}" ;;
		n|N) exit 110 ;;
		*) echo -e "${RED}Invalid Answer, Exiting the script.${NONE}" 
		   exit 120;;
	esac
fi

done

}

deletenfshome(){

read -sp "$(echo -e $GREEN"Please enter the password for ssh ---> "$NONE)" PASSWORD
echo "$PASSWORD" > ipa_password.txt && chmod 400 ipa_password.txt && printf "${CYAN}\nCreated the ipa_password.txt file with ro permissions.\n${NONE}"

if [[ ! -f "$FILE" ]]; then 
	read -p "Please enter the nfs export path on the nfs server without trailing slash ---> " EXPORT_PATH
	read -p "Please enter the nfs user name with permissions to write to the export dir ---> " SSH_USER
	read -p "Please enter the nfs FQDN ---> " NFS_SRV
else
	source nfs_creds.txt
fi

if [[ $(which sshpass 2> /dev/null) ]]; then
	sshpass -f ipa_password.txt ssh -o StrictHostKeyChecking=no $SSH_USER@$NFS_SRV "rm -rf $EXPORT_PATH/$USERNAME" && echo -e "${GREEN}Successfully deleted the user's home directory.${NONE}" && echo -e "${CYAN}Deleting the ipa_password.txt file.${NONE}" &&  rm -rf ipa_password.txt || { printf "${RED}Something went wrong.\nPlease check that you did everything correctly, maybe the password in the password file is incorrect.\nRun the script again.\n${NONE}"; rm -rf ipa_password.txt; exit 150;}

elif [[ ! $(which sshpass 2> /dev/null) ]]; then
	ipa user-del $USERNAME
	rm -rf ipa_password.txt
	read -p $'You don\'t have the sshpass utility.\nDo you want the script to install it ? (works only on centos/rhel/fedora) y|n ---> ' INSTALL
	case $INSTALL in
		y|Y) sudo yum install epel-release -y && sudo yum install sshpass -y 
		     echo "Please run the script again." ;;
		n|N) echo "Please install the sshpass utility on your own and run the script again."
		     exit ;;
	        *) echo "Invalid option, exiting the script."
		   exit 130 ;;
	esac

else 
	printf "Unknown error."
	exit 140

fi

}

## main script.

FILE=nfs_creds.txt
CURRENT_DATE=$(date '+%m-%d-%Y %H:%M:%S')
KRB_DATE=$(klist 2> /dev/null | tail -1 | awk '{print $3, $4}')
sudo sss_cache -E
read -p "$( echo -e $GREEN"Do you want to create or delete a user? create/delete ---> "$NONE)" MAIN

case $MAIN in
	create)
		if [[ $(klist 2> /dev/null) ]]; then
			if [[ "$CURRENT_DATE" > "$KRB_DATE" ]]; then
				kinit admin
				createuser
				mknfshome
				savenfscreds
			else
				createuser
				mknfshome
				savenfscreds
			fi
		else
			kinit admin
        		createuser
        		mknfshome
			savenfscreds
		fi ;;
	delete)
		if [[ $(klist 2> /dev/null) ]]; then
			if [[ "$CURRENT_DATE" > "$KRB_DATE" ]]; then
				kinit admin
				deleteuser
				savenfscreds
			else
				deleteuser
				savenfscreds
			fi
		else
			kinit admin
			deleteuser
			savenfscreds
		fi ;;

	*) echo -e "${RED}Invalid answer, exiting the script.${NONE}"
		exit ;;
esac