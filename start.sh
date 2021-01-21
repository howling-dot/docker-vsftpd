#!/bin/sh

#Remove all ftp users
grep '/ftp/' /etc/passwd | cut -d':' -f1 | xargs -n1 deluser

#Create users
#USERS='name1|password1|[folder1][|uid1] name2|password2|[folder2][|uid2]'
#may be:
# user|password foo|bar|/home/foo
#OR
# user|password|/home/user/dir|10000
#OR
# user|password||10000

#Default user 'ftp' with password 'alpineftp'

if [ -z "$USERS" ]; then
  USERS="ftp|alpineftp"
fi

for i in $USERS ; do
    NAME=$(echo $i | cut -d'|' -f1)
    PASS=$(echo $i | cut -d'|' -f2)
  FOLDER=$(echo $i | cut -d'|' -f3)
     UID=$(echo $i | cut -d'|' -f4)

  if [ -z "$FOLDER" ]; then
    FOLDER="/ftp/$NAME"
  fi

  if [ ! -z "$UID" ]; then
    UID_OPT="-u $UID"
  fi

  echo -e "$PASS\n$PASS" | adduser -h $FOLDER -s /sbin/nologin $UID_OPT $NAME
  mkdir -p $FOLDER
  chown $NAME:$NAME $FOLDER
  unset NAME PASS FOLDER UID
done


CONF_FILE="/etc/vsftp/vsftp.conf"

if [ "$1" = "ftp" ]; then
 echo "Launching vsftp on ftp protocol"
fi

if [ "$1" = "ftps" ]; then
 echo "Launching vsftp on ftps protocol"
 CONF_FILE="/etc/vsftp/vsftp_ftps.conf"
fi

if [ "$1" = "ftps_implicit" ]; then
 echo "Launching vsftp on ftps protocol in implicit mode"
 CONF_FILE="/etc/vsftp/vsftp_ftps_implicit.conf"
fi

if [ "$1" = "ftps_tls" ]; then
 echo "Launching vsftp on ftps with TLS only protocol"
 CONF_FILE="/etc/vsftp/vsftp_ftps_tls.conf"
fi

if [ -n "$PASV_ADDRESS" ]; then
  echo "Activating passv on $PASV_ADDRESS"
  echo "pasv_address=$PASV_ADDRESS" >> $CONF_FILE
 fi

# If TLS flag is set and no certificate exists, generate it
if [ ! -e /etc/vsftpd/private/vsftpd.pem ] && [[ "$CONF_FILE" == *"ftps"* ]]
then
    echo "Generating self-signed certificate"
    mkdir -p /etc/vsftpd/private

    openssl req -x509 -nodes -days 7300 \
        -newkey rsa:2048 -keyout /etc/vsftpd/private/vsftpd.pem -out /etc/vsftpd/private/vsftpd.pem \
        -subj "/C=FR/O=My company/CN=example.org"
    openssl pkcs12 -export -out /etc/vsftpd/private/vsftpd.pkcs12 -in /etc/vsftpd/private/vsftpd.pem -passout pass:

    chmod 755 /etc/vsftpd/private/vsftpd.pem
    chmod 755 /etc/vsftpd/private/vsftpd.pkcs12
fi

&>/dev/null /usr/sbin/vsftpd $CONF_FILE
