#!/bin/bash
#+-------------------------------------------------------------------------+
# Author: Team @ Hooduku for HoodukuCloud
# Date : 09 SEP 2010
# Purpose: This Script automates the setting up of Nagios Server.
# Send feedback to info@hooduku.com 
# +-------------------------------------------------------------------------+
username="nagios"			# DO NOT CHANGE IT
password="n@g!0&Flexi"			# CHANGE THE PASSWORD IF REQUIRE
Nag_web_user="nagiosadmin" 		# DO NOT CHANGE IT
Nag_web_psw="Flex!n@g!0s"		# CHANGE THE PASSWORD IF REQUIRE

Nagios_Core="http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.5.0.tar.gz"
Nagios_Plugins="http://prdownloads.sourceforge.net/sourceforge/nagiosplug/nagios-plugins-1.4.16.tar.gz"
NRPE="http://prdownloads.sourceforge.net/sourceforge/nagios/nrpe-2.14.tar.gz"
GD="http://autoapm.googlecode.com/files/gd-2.0.33.tar.gz"

txtrst=$(tput sgr0) # Text reset
txtred=$(tput setaf 1) # Red
txtgrn=$(tput setaf 2) # Green
txtylw=$(tput setaf 3) # Yellowlibldap-2.4-2
txtblu=$(tput setaf 4) # Blue
txtpur=$(tput setaf 5) # Purple
txtcyn=$(tput setaf 6) # Cyan
txtwht=$(tput setaf 7) # White
txtbld=$(tput bold) # bold	

welcome_msg()
{
	echo -e "\n\t\033[44;37;5m###################################\033[0m"
	echo -e "\t\033[44;37;5m#            Welcome to           #\033[0m"
	echo -e "\t\033[44;37;5m#  Network Monitoring Tool Setup  #\033[0m"
	#echo -e "\t\033[44;37;5m###################################\033[0m\n"
}
#ln -s /etc/init.d/nagios /etc/rcS.d/S99nagios
install_type()
{
	echo -e "\t\033[44;37;5m#  -----------------------------  #\033[0m"
	echo -e "\t\033[44;37;5m#  1) Nagios Server Install       #\033[0m"
	echo -e "\t\033[44;37;5m#  2) Cacti Server Install        #\033[0m"
	echo -e "\t\033[44;37;5m###################################\033[0m\n"
	read -p '        Enter (1 or 2) to Start the Install : ' USER_IN 
}

chk_user()
{
	if [ $(whoami) != "root" ]
	then
		echo -e "\n\t\033[44;37;5m###### WARNING ######\033[0m"
		echo -e "\t${txtylw}${txtbld}Sorry ${txtgrn}$(whoami)${txtrst}${txtylw}${txtbld}, you must login as root user to run this script.${txtrst}" 
		echo -e "\t${txtylw}${txtbld}Please become root user using 'sudo -s' and try again.${txtrst}"
		echo -e
		echo -e "\t${txtred}${txtbld}Quitting Installer.....${txtrst}\n"
		sleep 3
	exit 1
	fi
}

####### MAIN PROGRAME #############
# Os Specifc tweaks do not change anything below ;)
chk_user
OSREQUIREMENT=`cat /etc/issue | awk '{print $1}' | sed 's/Kernel//g'`
if [ "$OSREQUIREMENT" = "Ubuntu" ]
then
welcome_msg
install_type

	case ${USER_IN} in
   	  1)	##### Start Nagios installer #####
				echo -e '\033[31m\n\tWelcome to the Nagios Core & Nagios Plugins Autoinstaller Script for Ubuntu!\n\tUser interaction will be necessary!\n\tNeeded packages are going to be installed via apt!\n\033[m'
				sleep 4 
				apt-get update
				apt-get -y --force-yes install apache2 build-essential wget perl openssl 
				apt-get -y --force-yes install libssl-dev openssh-server openssh-client ntpdate snmp smbclient libldap-2.4-2 libldap2-dev 
				apt-get -y --force-yes install mysql-server libmysqlclient-dev qstat libnet-snmp-perl mrtg nut unzip
				apt-get -y --force-yes install make gcc g++ build-essential 
				apt-get -y --force-yes install libgd2-xpm libgd2-xpm-dev libgd2 libgd-dev libpng12-dev libjpeg62-dev libgd-tools libpng3-dev
				echo -e '\n\tCreating a new nagios user account.'
				sleep 2
				#username="nagios"
				#password="n@g!0&Flexi"
				egrep "^$username" /etc/passwd >/dev/null
				if [ $? -eq 0 ]; 
				then
					echo -e "$username exists!"
				else
					pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
					useradd -p $pass $username
					[ $? -eq 0 ] && echo -e "User has been added to system!" || echo -e "Failed to add a user!"
				fi
				echo -e "\n\tCreating Group and User for Nagios!"
				sleep 2
				/usr/sbin/groupadd nagios
				/usr/sbin/groupadd nagcmd
				#useradd -u 9000 -g nagios -G nagcmd -d /usr/local/nagios -c "Nagios Admin" nagios
				/usr/sbin/usermod -G nagios nagios
				/usr/sbin/usermod -G nagcmd nagios
				/usr/sbin/usermod -G nagcmd www-data
				mkdir -p /opt/download
				cd /opt/download
				echo -e '\n\033[31m\nNagios Core and Nagios Plugins are downloaing !!! \n\tPlease Wait....\033[m\n'
				#---- Nagios Core ----#
				wget $Nagios_Core 
				#---- Nagios Plugins -----#
				wget $Nagios_Plugins 
				#---- NRPE -----#
				wget $NRPE
				#---- GD -----#
				wget $GD  
				sleep 2 
				echo "\nExtracting downloaded files....\n"
				tar -xvf nagios-3.5.0.tar.gz
				tar -xvf nagios-plugins-1.4.16.tar.gz
				tar -xvf nrpe-2.14.tar.gz
				tar -xvf gd-2.0.33.tar.gz
				sleep 2
				echo "\nRemoving temp files....\n"
				rm nagios-3.5.0.tar.gz nagios-plugins-1.4.16.tar.gz nrpe-2.14.tar.gz gd-2.0.33.tar.gz
				sleep 2
				echo "\nInstalling the GD-Utils...."
				sleep 2				
				cd gd-2.0.33
				./configure
				make && make install
				
				echo "\n\nInstalling the Nagios Core...."			
				sleep 2
				cd ../nagios-3.5.0 
				./configure --with-command-group=nagcmd
				sleep 1
				make all
				make install
				#make install-base
				make install-init
				make install-config
				make install-commandmode
				make install-webconf
				echo -e '\033[31m\nGoing to add the User "nagios" for the Webinterface!\n\033[m'
				sleep 2
				htpasswd -cb /usr/local/nagios/etc/htpasswd.users $Nag_web_user $Nag_web_psw
				#htpasswd -cb /usr/local/nagios/etc/htpasswd.users nagiosadmin Flex!n@g!0s				
				#htpasswd -c htpasswd.users nagios
				#chmod 600 /usr/local/nagios/etc/htpasswd.users
				
				echo -e '\033[31m\nNagios installation finished! Going to install the nagios-plugins!\n\033[m'
				sleep 2
				#perl -MCPAN -e 'install Net::SNMP'
				echo "\n\nInstalling the Nagios Plug-ins...."			
				sleep 2
				cd ../nagios-plugins-1.4.16
				#./configure --sysconfdir=/etc/nagios --localstatedir=/var/nagios --enable-perl-modules
				./configure --with-nagios-user=nagios --with-nagios-group=nagios
				sleep 1
				make clean 
				make
				make install
				#ln -s /etc/init.d/nagios /etc/rcS.d/S99nagios 
				echo -e "\n\nVerify the sample Nagios configuration files."
				/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg	
				sleep 2
				echo -e "\n\nAdding to statup...."			
				sleep 1  			
				sudo update-rc.d -f nagios defaults 	  			
 	  			#update-rc.d nagios defaults 99
				/etc/init.d/apache2 reload 
				/etc/init.d/nagios start
				sleep 2
				
				echo -e "\n\nInstalling the NRPE...."
				cd ../nrpe-2.14
				./configure
				make all
				make install-plugin
				#make install-daemon
				#make install-daemon-config
				
				#make install-xinetd
				cfg_dir="/usr/local/nagios/etc/objects"
				mkdir -p $cfg_dir/remote
				cd $cfg_dir/remote
				cp /usr/local/nagios/etc/nagios.cfg /usr/local/nagios/etc/nagios.cfg.orginal
				echo -e "\ncfg_dir=$cfg_dir/remote" >> /usr/local/nagios/etc/nagios.cfg

cat > $cfg_dir/remote/nrpe-command.cfg <<"EOF"
define command{
  command_name    check_nrpe
  command_line $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}
EOF

cat > $cfg_dir/remote/nrpe-hosts.cfg <<"EOF"				
#Example Host template
#define host{
#use Linux-Client
#host_name $HOSTNAME
#alias Linux Server
#address <IP_addr>
#}

EOF

cat > $cfg_dir/remote/nrpe-services.cfg <<"EOF"
# Hostgroup definition
define hostgroup{
hostgroup_name  Cloud-servers ; The name of the hostgroup
alias           Linux Servers ; Long name of the group
members         localhost
}

# 'Live Databases' service group definition
define servicegroup{
servicegroup_name HTTP
alias Web Server
members localhost,HTTP,localhost,SSH,localhost.PING
}
define servicegroup{
servicegroup_name Usage
alias CPU and Disk
members localhost,Root Partition,localhost,Current Users,localhost,Total Processes,localhost,Swap Usage,localhost,Current Load
}

define service{
    use                             generic-service         ; Name of service template to use
    host_name                       localhost
    service_description             PING
    check_command			check_nrpe!check_ping
    }
# Define a service to check the disk space of the root partition
# on the local machine.  Warning if < 20% free, critical if
# < 10% free space on partition.
define service{
    use                             generic-service         ; Name of service template to use
    host_name                       localhost
    service_description             Root Partition
    check_command			check_nrpe!check_disk
    }
# Define a service to check the number of currently logged in
# users on the local machine.  Warning if > 20 users, critical
# if > 50 users.
define service{
    use                             generic-service         ; Name of service template to use
    host_name                       localhost
    service_description             Current Users
    check_command			check_nrpe!check_users
    }
# Define a service to check the number of currently running procs
# on the local machine.  Warning if > 250 processes, critical if
# > 400 users.
define service{
    use                             generic-service         ; Name of service template to use
    host_name                       localhost
    service_description             Total Processes
    check_command			check_nrpe!check_procs
    }
# Define a service to check the load on the local machine. 
define service{
    use                             generic-service         ; Name of service template to use
    host_name                       localhost
    service_description             Current Load
    check_command			check_nrpe!check_load
    }
# Define a service to check the swap usage the local machine. 
# Critical if less than 10% of swap is free, warning if less than 20% is free
define service{
    use                             generic-service         ; Name of service template to use
    host_name                       localhost
    service_description             Swap Usage
    check_command			check_nrpe!check_swap
    }
# Define a service to check SSH on the local machine.
# Disable notifications for this service by default, as not all users may have SSH enabled.
define service{
    use                             generic-service         ; Name of service template to use
    host_name                       localhost
    service_description             SSH
    check_command			check_nrpe!check_ssh
    notifications_enabled		0
    }
# Define a service to check HTTP on the local machine.
# Disable notifications for this service by default, as not all users may have HTTP enabled.
define service{
    use                             generic-service         ; Name of service template to use
    host_name                       localhost
    service_description             HTTP
    check_command			check_nrpe!check_http
    notifications_enabled		0
    }
EOF
				
				/etc/init.d/nagios restart	
				echo -e "\n\nVerify the sample Nagios configuration files."
				/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg	
				sleep 2
				echo -e "\n\tNow Nagios is ready to be used via: http://localhost/nagios"
				echo -e '\n\n\033[31m\tInstallation of Nagios Core and the Nagios-Plugins have been finished!\n\tThanks for using this Script!\n\n\t\033[32mLeave your feedback at vasanth_kg@hotmail.com\033[m'
    			##### END Nagios #####    
           ;;
           
   	  2)	##### Start Cacti installer #####
				echo -e '\033[31m\n\tWelcome to the Cacti Autoinstaller Script for Ubuntu!\n\tUser interaction will be necessary!\n\tNeeded packages are going to be installed via apt!\n\033[m'
				sleep 2
				apt-get update
				apt-get -y --force-yes install apache2 apache2.2-common apache2-mpm-prefork apache2-utils 
				apt-get -y --force-yes install make gcc g++ build-essential 
				apt-get -y --force-yes install mysql-server mysql-client libmysqlclient-dev libpango1.0-dev libxml2-dev
				apt-get -y --force-yes install php5 libapache2-mod-php5 php5-common php5-cgi php5-cli php5-snmp php5-mysql
				#apt-get -y --force-yes install snmp snmpd
				apt-get -y --force-yes install rrdtool
				#### Installing Cacti via Apt|
				apt-get -y --force-yes install cacti-cactid
				[ $? -eq 0 ] && echo -e "\n\tNow Cacti is ready to be used via: http://localhost/cacti The default login and password are admin." && echo -e "\tCacti will check if all the required tools are correctly installed.\n"
				echo "" > /usr/share/cacti/cacti_clients


				##### END Cacti #####    
           ;;
   	  *)	##### Quit installer if User input doesn't match #####
           	echo -e "\n\t${txtylw}${txtbld}Please enter 1 - to install NAGIOS, 2 - to install CACTI.${txtrst}"
		echo -e "\n\t${txtred}${txtbld}Quitting Installer.....${txtrst}\n"
		exit 0           
           ;;
		esac        
else
	echo -e "\n\t\033[44;37;5mThis Script must be executed Only on Ubuntu Flavor !!!\033[0m"
   exit 1
fi