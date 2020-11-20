#!/bin/bash

#Check domain A record mapping
read -p "Please enter client name: " CLIENTNAME
SITE=$CLIENTNAME"-tx.appiloque.com"
echo Check if A record is pointed to correct IP Address
host -t a $SITE
IPADD="y"
while [ $IPADD != "y" ] || [ $IPADD != "n" ]
do
	read -p "Is IP Address correct? [y/n] " IPADD
	if [ $IPADD == "y" ]
	then
		echo START DOWNLOADING PACKAGES
		apt-get update
		echo DONE DOWNLOADING PACKAGES

		echo START UPDATING PACKAGES
		apt-get upgrade
		echo DONE UPDATING PACKAGES

		echo OVERRIDE DEFAULT LANGUAGE AND CHARACTER ENCODING
		export LC_ALL="en_US.UTF-8"
		echo DONE OVERRIDE DEFAULT LANGUAGE AND CHARACTER ENCODING

		echo START INSTALLING EASYENGINE
		wget -qO ee rt.cx/ee4 && sudo bash ee
		ee cli version
		echo DONE INSTALLING EASYENGINE

		#CREATE SITE
		echo START CREATING SITE
		sudo ee site create $SITE --type=html --ssl=le 
		echo DONE CREATING SITE

		#SFTP SETUP
		echo SETTING UP SFTP
		sudo passwd www-data
		#change entire line 13 from /usr/sbin/nologin to /bin/bash
		echo CHANGING /usr/sbin/nologin to /bin/bash in /etc/passwd
		sed -i '13s_.*_www-data:x:33:33:www-data:/var/www:/bin/bash_' /etc/passwd
		#change password authentication to yes (line 56)
		echo CHANGING PasswordAuthentication to yes in /etc/ssh/sshd_config
		perl -pi -e 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
		#restart service
		echo RESTARING SERVICE
		service ssh restart
		echo DONE RESTARTING SERVICE
		#give permission
		echo GIVING PERMISSION
		chmod g+x /var/lib/docker/volumes
		chgrp www-data /var/lib/docker/volumes
		echo DONE GIVING PERMISSION
		#END OF SFTP SETUP

		#ADD NEW SFTP USER
		echo START ADDING NEW SFTP USER
		USERNAME=$CLIENTNAME"tx"
		useradd -G www-data -ms /bin/false $USERNAME
		passwd $USERNAME
		#create home directory
		echo CREATE HOME DIRECTORY FOR USER $USERNAME
		mkdir -p /home/$USERNAME/$SITE/htdocs
		#set up permission
		echo START SETTING UP PERMISSION
		chown $USERNAME:www-data /home/$USERNAME/$SITE
		chown root:root /home/$USERNAME/
		chown root:root /home/
		echo DONE SETTING UP PERMISSION

		#change entire line 116 from /usr/lib/openssh/sftp-server to internal-sftp
		echo CHANGING /usr/lib/openssh/sftp-server to internal-sftp in /etc/ssh/sshd_config
		sed -i '116s_.*_Subsystem	sftp	internal-sftp_' /etc/ssh/sshd_config
		echo ADDING CHROOT
		echo "Match group www-data" >> /etc/ssh/sshd_config
		echo "X11Forwarding no" >> /etc/ssh/sshd_config
		echo "ChrootDirectory %h" >> /etc/ssh/sshd_config
		echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
		echo "ForceCommand internal-sftp" >> /etc/ssh/sshd_config
		echo ADDING CHROOT SUCCESSFULLY

		#restart service
		echo RESTARING SERVICE
		service ssh restart
		echo DONE RESTARTING SERVICE

		#set up webroot permission
		echo START SETTING UP WEBROOT PERMISSION
		chmod g+s /opt/easyengine/sites/$SITE/app/htdocs -R
		chmod 775 /opt/easyengine/sites/$SITE/app/htdocs -R
		echo DONE SETTING UP WEBROOT PERMISSION

		#mount webroot
		echo START MOUNTING WEBROOT IN SFTP HOME DIRECTORY
		mount --bind /opt/easyengine/sites/$SITE/app/htdocs /home/$USERNAME/$SITE/htdocs
		echo DONE MOUNTING WEBROOT IN SFTP HOME DIRECTORY
	
		#show site info
		ee site info $SITE
		break

	elif [ $IPADD == "n" ]
	then
		echo Please change your IP Address and rerun the script.
		break

	else
		echo "Invalid input! Please enter y (yes) or n (no)."
	fi
done
