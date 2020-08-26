#!/bin/bash
read -p "Have you save crontab file for the first time? [y/n] " CRON
if [ $CRON == "y" ]
then
	#Check domain A record mapping
	read -p "Please enter site url: " SITE
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

			#SITE TYPE
			SITETYPE=1
			while [ $SITETYPE != 1 ] || [ $SITETYPE != 2 ]
			do
				echo Select your EE site type: 
				echo 1. wp
				echo 2. html
				read -p "Choose [1/2]: " SITETYPE
				if [ $SITETYPE == 1 ]
				then
					SITETYPE="wp"
					break
				elif [ $SITETYPE == 2 ]
				then
					SITETYPE="html"
					break
				else
					echo Invalid input! Please enter 1 or 2.
				fi
			done
			
			#SSL
			CERT="y"
			while [ $CERT != "y" ] || [ $CERT != "n" ]
			do
				read -p "SSL setup required? [y/n] " CERT
				if [ $CERT == "y" ]
				then
					CERT="--ssl=le"
					break
				elif [ $CERT == "n" ]
				then
					CERT=""
					break
				else
					echo "Invalid input! Please enter y (yes) or n (no)."
				fi
			done

			#CREATE SITE
			echo START CREATING SITE
			sudo ee site create $SITE --type=$SITETYPE $CERT --admin-user=appiloque --admin-email=xiuting.chan@appiloque.com
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
			echo GIVING PERMISION
			chmod g+x /var/lib/docker/volumes
			chgrp www-data /var/lib/docker/volumes
			echo DONE GIVING PERMISION
			#END OF SFTP SETUP

			echo ADDING CRONS TO CRONTAB
			(crontab -l ; echo "SHELL=/bin/bash")| crontab -
			(crontab -l ; echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")| crontab -
			(crontab -l ; echo "0 0 * * 0 date >> /opt/easyengine/logs/cron.log 2>&1")| crontab -
			(crontab -l ; echo "0 0 * * 0 /usr/local/bin/ee site ssl-renew --all >> /opt/easyengine/logs/cron.log 2>&1")| crontab -
			echo ADDING CRONS SUCCESSFULLY

			echo START CHANGING LOGIN SLUG 
			sed -i '25i location ~* /admin/ {' /opt/easyengine/sites/$SITE/config/nginx/conf.d/main.conf
			sed -i '26i     rewrite ^/admin/(.*) /wp-admin/$1 last;' /opt/easyengine/sites/$SITE/config/nginx/conf.d/main.conf
			sed -i '27i }' /opt/easyengine/sites/$SITE/config/nginx/conf.d/main.conf
			sed -i '28i location = /login {' /opt/easyengine/sites/$SITE/config/nginx/conf.d/main.conf
			sed -i '29i   rewrite ^(.*)$ /wp-login.php;' /opt/easyengine/sites/$SITE/config/nginx/conf.d/main.conf
			sed -i '30i }' /opt/easyengine/sites/$SITE/config/nginx/conf.d/main.conf

			echo RESTARTING NGINX
			ee site restart $SITE --nginx

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
else
	echo Please open and save your crontab file
fi
