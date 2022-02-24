## This script installs the ipa client command and configure autofs to mount to the user's home directory in the nds server. 

import subprocess
import os

operating_system = str(subprocess.check_output(['uname', '-a'], stderr=subprocess.DEVNULL))

## This function checks tat you have the supported OS and if you do, it checks that you have the freeipa-client package installed. If not, it'll install&configure it.

def ipa_func():
    ipa_user = input("Enter the ipa administrative user: ")
    ipa_password = input("Enter the ipa adminstator password: ")
    ipa_domain = input("Enter the domain name: ").lower()
    ipa_server = input("Enter the server's FQDN: ").lower()

    if "Ubuntu" in operating_system:
        ipa = str(subprocess.check_output(['apt', 'list', '--installed', 'freeipa-client'], stderr=subprocess.DEVNULL))
        if "freeipa-client" not in ipa:
            subprocess.run(['apt', 'install', 'freeipa-client', '-y'])
        try:
            subprocess.check_output(['ipa-client-install', '-p', ipa_user, '-w', ipa_password, '--domain', ipa_domain, '--server', ipa_server, '--unattended'])
        except subprocess.CalledProcessError:
            subprocess.run(['ipa-client-install', '--uninstall'])
            exit()
    else:
        print("Your distribution is not supported.")
        exit()

## This function checks that you have the supported operating_system and if you do, it checks that you have the autofs package installed. If not, it'll install it.

def autofs_func():
    if "Ubuntu" in operating_system:
        autofs = str(subprocess.check_output(['apt', 'list', '--installed', 'autofs'], stderr=subprocess.DEVNULL))
        if "autofs" not in autofs:
            subprocess.call(['apt', 'install', 'autofs', '-y'])
    else:
        print("Your distribution is not supported.")
        exit()

## This function configures the autofs necessary files.

def configuration_func():
    nfs_ip = input("Enter the ip of the NFS server: ")
    with open ('/etc/auto.master.d/ipa.autofs', 'w') as master:
        master.write('/home/ipa /etc/auto.ipa')
    with open ('/etc/auto.ipa','w') as ipa:
        ipa.write('* -fstype=nfs4 ' + nfs_ip+':/export/home/&')
    print('The configuration of autofs has finished.')
    subprocess.run(['systemctl', 'restart', 'autofs'])

## Main script

if not os.geteuid() == 0:
    exit('This script must be run with root privileges.')
else:
    try:
        ipa_func()
        autofs_func()
        configuration_func()
    except:
        print('Something went wrong, please contact your system administrator.')
    finally:
        print('The script has finished.')