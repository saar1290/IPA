FROM jrei/systemd-centos

COPY set_dc.sh set_dc.sh
COPY entry.sh entry.sh
ENV TZ=Asia/Jerusalem

RUN yum update -y \
&& yum install -y @idm:DL1 \
&& yum install freeipa-server ipa-server-dns bind-dyndb-ldap rsync crontabs -y \
&& echo "0 0 * * * /usr/sbin/ipa-backup" > /var/spool/cron/root \
&& echo "0 0 * * * /usr/bin/find /var/lib/ipa/backup/ipa* -maxdepth 1 -mtime +2 -exec rm -rf {} \;" >> /var/spool/cron/root \
&& ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone