#! /bin/bash
#+-------------------------------------------------------------------------+
# Author: Team @ Hooduku for Hooduku Cloud
# Date : 09 SEP 2010
# Purpose: This Script automates the setting up of Nagios and Cacti Agents on every Instance.
# Send feedback to info@hooduku.com
#+-------------------------------------------------------------------------+
SERVER_IP="174.143.168.120"
LOCAL_IP=`/sbin/ifconfig eth0 | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}'`
FTP_USER="flexi"
FTP_PSW="Ftp_flex!"
username="nagios"
password="Flexi"

NAG_SER_FILE="nrpe-services.cfg"	# DO NOT CHANGE IT
NAG_HOST_FILE="nrpe-hosts.cfg"		# DO NOT CHANGE IT
CACTI_CLIENT="cacti_clients"		# DO NOT CHANGE IT

Nagios_Plugins="http://prdownloads.sourceforge.net/sourceforge/nagiosplug/nagios-plugins-1.4.15.tar.gz"
NRPE="http://prdownloads.sourceforge.net/sourceforge/nagios/nrpe-2.12.tar.gz"

txtrst=$(tput sgr0) # Text reset
txtred=$(tput setaf 1) # Red
txtgrn=$(tput setaf 2) # Green
txtylw=$(tput setaf 3) # Yellow
txtblu=$(tput setaf 4) # Blue
txtpur=$(tput setaf 5) # Purple
txtcyn=$(tput setaf 6) # Cyan
txtwht=$(tput setaf 7) # White
txtbld=$(tput bold) # bold	

welcome_msg()
{
	echo -e "\n\t\033[44;37;5m###################################\033[0m"
	echo -e "\t\033[44;37;5m#            Welcome to           #\033[0m"
	echo -e "\t\033[44;37;5m#   Nagios And Cacti Agent Setup  #\033[0m"
	echo -e "\t\033[44;37;5m###################################\033[0m\n"
}

chk_user()
{
	if [ "$(id -u)" != "0" ];
	then
		echo -e "\n\t\033[44;37;5m###### WARNING ######\033[0m"
		echo -e "\t${txtylw}${txtbld}Sorry ${txtgrn}$(whoami)${txtrst}${txtylw}${txtbld}, you must login as root user to run this script.${txtrst}" 
		echo -e "\t${txtylw}${txtbld}Please become root user using 'sudo -s' and try again.${txtrst}"
		echo
		echo -e "\t${txtred}${txtbld}Quitting Installer.....${txtrst}\n"
		sleep 3
		exit 1
	fi
}

install_Nagios()
{
		echo -e '\033[31m\n\tWelcome to the Nagios Agent Autoinstaller Script!\n\tNeeded packages are going to be installed....\n\033[m'
		sleep 3
		yum install gcc glibc glibc-common libstdc++-devel gcc-c++ openssl openssl-devel ftp perl -y
		yum install gd gd-devel xinetd -y
		rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm
		yum list *NCFTP*
		yum install ncftp -y
		sleep 2
		#---- Nagios Plugins -----#
		mkdir -p /opt/download; cd /opt/download
		echo -e "\n\nPlease wait.....Downloading required Packages !!!"
		sleep 1		
		wget $Nagios_Plugins 
		#---- NRPE -----#
		wget $NRPE
		echo -e "\n\nPlease wait.....Extracting Downloaded Packages !!!"		
		sleep 2
		tar -xvf nagios-plugins-1.4.15.tar.gz
		tar -xvf nrpe-2.12.tar.gz
		rm nagios-plugins-1.4.15.tar.gz nrpe-2.12.tar.gz
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
		
		#Add  nagcmd  group
		/usr/sbin/groupadd nagcmd
		/usr/sbin/usermod -a -G nagcmd nagios
		sleep 3		
		cd nagios-plugins-1.4.15
		./configure 
		make all
		make install
		chown nagios.nagios /usr/local/nagios
		chown -R nagios.nagios /usr/local/nagios/libexec
		sleep 3
		echo -e "\n\nPlease wait....Installing NRPE !!!!"
		sleep 2
		cd ../nrpe-2.12
		./configure 
		make all
		make install-plugin
		make install-daemon
		make install-daemon-config
		make install-xinetd
		
cat > /etc/xinetd.d/nrpe <<"EOF"				
# default: on
# description: NRPE (Nagios Remote Plugin Executor)
service nrpe
{
        flags           = REUSE
        socket_type     = stream
        port            = 5666
        wait            = no
        user            = nagios
        group           = nagios
        server          = /usr/local/nagios/bin/nrpe
        server_args     = -c /usr/local/nagios/etc/nrpe.cfg --inetd
        log_on_failure  += USERID
        disable         = no
        only_from       = 127.0.0.1 
}
EOF
		if [ -e  /etc/xinetd.d/nrpe ];
		then
		    #sed -e "s/127.0.0.1/127.0.0.1 $SERVER_IP/" /etc/xinetd.d/nrpe
		    sed "/only_from/s/$/ $SERVER_IP/g" /etc/xinetd.d/nrpe > /etc/xinetd.d/temp.txt; mv /etc/xinetd.d/temp.txt /etc/xinetd.d/nrpe
		fi
		if [ -e  /usr/local/nagios/etc/nrpe.cfg ];
		then
		  echo "command[check_disk]=/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /dev/sda1" >> /usr/local/nagios/etc/nrpe.cfg
		  echo "command[check_procs]=/usr/local/nagios/libexec/check_procs -w 150 -c 200" >> /usr/local/nagios/etc/nrpe.cfg
		  echo "command[check_swap]=/usr/local/nagios/libexec/check_swap -w 15% -c 7%" >> /usr/local/nagios/etc/nrpe.cfg
		fi
		chmod a+x /etc/xinetd.d/nrpe
		#chkconfig --add nrpe
		#chkconfig --level 235 nrpe on
		echo -e "\nnrpe 5666/tcp # NRPE" >> /etc/services
		service xinetd restart
		netstat -at | grep nrpe
		#iptables -I RH-Firewall-1-INPUT -p tcp -m tcp –dport 5666 -j ACCEPT
		#service iptables save
		echo -e "\n\nNagios Client Installation is finished !!!!"		
}

install_Cacti()
{
	echo -e '\033[31m\n\tWelcome to the Cacti Agent Autoinstaller Script!\n\tNeeded packages are going to be installed....\n\033[m'
	sleep 3
	yum install gcc glibc glibc-common libstdc++-devel gcc-c++ openssl openssl-devel ftp perl -y
	yum install net-snmp net-snmp-utils net-snmp-devel -y
	rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm
	yum list *NCFTP*
	yum install ncftp -y
	sleep 2
	cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.original
	#echo -e "# Allow Systems Management Data Engine SNMP to connect to snmpd using SMUX\nsmuxpeer .1.3.6.1.4.1.674.10892.1" >> /etc/snmp/snmpd.conf
	if [ -e /etc/default/snmpd ];
	then 
		echo -e "\tModifying SNMPD binds to all.\n"
		sed -e "s/ 127.0.0.1//g" /etc/default/snmpd > temp.txt; mv temp.txt /etc/default/snmpd
	fi
	
if [ -e /etc/snmp/snmpd.conf ]; 
then
cat > /etc/snmp/snmpd.conf <<"EOF"				
com2sec readonly  default         public
group MyROSystem v1        paranoid
group MyROSystem v2c       paranoid
group MyROSystem usm       paranoid
group MyROGroup v1         readonly
group MyROGroup v2c        readonly
group MyROGroup usm        readonly
group MyRWGroup v1         readwrite
group MyRWGroup v2c        readwrite
group MyRWGroup usm        readwrite
view all    included  .1                               80
view system included  .iso.org.dod.internet.mgmt.mib-2.system
access MyROSystem ""     any       noauth    exact  system none   none
access MyROGroup ""      any       noauth    exact  all    none   none
access MyRWGroup ""      any       noauth    exact  all    all    none
syslocation Unknown (configure /etc/snmp/snmpd.local.conf)
syscontact Root <root@localhost> (configure /etc/snmp/snmpd.local.conf)
smuxpeer .1.3.6.1.4.1.674.10892.1
EOF
		#sed -e "s/view.*system.*included.*.1.3.6.1.2.1.1/view system included  .iso.org.dod.internet.mgmt.mib-2.system/" /etc/snmp/snmpd.conf > temp.txt; mv temp.txt /etc/snmp/snmpd.conf
		#sed -e "s/com2sec.*$/com2sec readonly default public/" /etc/snmp/snmpd.conf > temp.txt; mv temp.txt /etc/snmp/snmpd.conf					
fi
	sleep 2

	service snmpd start
	chkconfig snmpd on
	echo -e "\n\nCacti Client Installation is finished !!!!"		
}

Nag_ftp_get()
{
FILE_NAME=$1
ncftp -u$FTP_USER -p$FTP_PSW $SERVER_IP<<EOF
bin
passive
set confirm-close no
cd /usr/local/nagios/etc/objects/remote
lcd /usr/local/nagios
get $FILE_NAME
passive
quit
EOF
}

Nag_ftp_put()
{
FILE_NAME=$1
ncftp -u$FTP_USER -p$FTP_PSW $SERVER_IP<<EOF
bin
passive
set confirm-close no
lcd /usr/local/nagios
cd /usr/local/nagios/etc/objects/remote
put $FILE_NAME
passive
quit
EOF
}

cacti_ftp_get()
{
FILE_NAME=$1
ncftp -u$FTP_USER -p$FTP_PSW $SERVER_IP<<EOF
bin
passive
set confirm-close no
lcd /etc/snmp
cd /usr/share/cacti
get $FILE_NAME
passive
quit
EOF
}

cacti_ftp_put()
{
FILE_NAME=$1
ncftp -u$FTP_USER -p$FTP_PSW $SERVER_IP<<EOF
bin
passive
set confirm-close no
lcd /etc/snmp
cd /usr/share/cacti
put $FILE_NAME
passive
quit
EOF
}

Nag_config_modify()
{
    cd /usr/local/nagios
    Nag_ftp_get "$NAG_SER_FILE"
    awk "/members/{c++;if(c==1){sub(\"$\",\",$HOSTNAME\");}if(c==2){sub(\"$\",\",$HOSTNAME,HTTP,$HOSTNAME,SSH,$HOSTNAME,PING\");}if(c==3){sub(\"$\",\",$HOSTNAME,Root Partition,$HOSTNAME,Current Users,$HOSTNAME,Total Processes,$HOSTNAME,Swap Usage,$HOSTNAME,Current Load\");}}1" $NAG_SER_FILE > temp.txt; mv temp.txt $NAG_SER_FILE
    #sed "/members/s/$/,$HOSTNAME/g" $NAG_SER_FILE > temp.txt; mv temp.txt $NAG_SER_FILE
    sed "/host_name/s/$/,$HOSTNAME/g" $NAG_SER_FILE > temp.txt; mv temp.txt $NAG_SER_FILE
    Nag_ftp_put "$NAG_SER_FILE"
    rm $NAG_SER_FILE
    Nag_ftp_get "$NAG_HOST_FILE"
    echo "" >> $NAG_HOST_FILE
    echo "define host{" >> $NAG_HOST_FILE
    echo "use linux-server" >> $NAG_HOST_FILE
    echo "host_name $HOSTNAME" >> $NAG_HOST_FILE
    echo "alias $HOSTNAME-Server" >> $NAG_HOST_FILE
    echo "address $LOCAL_IP" >> $NAG_HOST_FILE
    echo "}" >> $NAG_HOST_FILE
    Nag_ftp_put "$NAG_HOST_FILE"
    rm $NAG_HOST_FILE
}

Cacti_config_modify()
{
    cd /etc/snmp
    cacti_ftp_get "$CACTI_CLIENT"
    if [ -e $CACTI_CLIENT ];
    then
	echo "HOSTNAME:$LOCAL_IP:$HOSTNAME" >> $CACTI_CLIENT
	cacti_ftp_put "$CACTI_CLIENT"
	rm $CACTI_CLIENT
    fi
    echo -e "Modified config files..... "
}

####### MAIN PROGRAME #############
chk_user
# Os Specifc tweaks do not change anything below ;)
OSREQUIREMENT=`cat /etc/issue | awk '{print $1}' | sed 's/Kernel//g'`
OSREQ=`cat /etc/redhat-release | awk '{print $1}' | sed 's/Kernel//g'`

if [ $OSREQ = "CentOS" ];
then
			welcome_msg
                        sleep 2
                        # Nagios Client install
                        install_Nagios
                        # Config file modification
                        Nag_config_modify
                        # END of Nagios
                        sleep 3
                        # Cacti Client Install
                        install_Cacti
                        # CACTI Config file modification
                        Cacti_config_modify
                        #### END Cati Agent #####

else

case ${OSREQUIREMENT} in
     Ubuntu)
    			welcome_msg
			sleep 4
    			##### Nagios Agent #####
			apt-get update
			apt-get -y --force-yes install perl openssl libssl-dev ftp ncftp
			#apt-get -y --force-yes install mysql-server libmysqlclient-dev qstat libnet-snmp-perl mrtg nut unzip
			apt-get -y --force-yes install make gcc g++ build-essential xinetd
			apt-get -y --force-yes install libgd2-xpm libgd2-xpm-dev libgd2 libgd-dev libpng12-dev libjpeg62-dev libgd-tools libpng3-dev
			echo -e '\n\tCreating a new nagios user account.'
			sleep 2
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
    			mkdir -p /opt/download; cd /opt/download
			echo -e '\n\033[31m\nNagios Plugins and NRPE are downloaing !!! \n\tPlease Wait....\033[m\n'
			#---- Nagios Plugins -----#
			wget $Nagios_Plugins 
			#---- NRPE -----#
			wget $NRPE
			sleep 2 
			echo "\nExtracting downloaded files....\n"
			tar -xvf nagios-plugins-1.4.15.tar.gz
			tar -xvf nrpe-2.12.tar.gz
			sleep 2
			echo "\nRemoving temp files....\n"
			rm nagios-plugins-1.4.15.tar.gz nrpe-2.12.tar.gz
			sleep 2
			echo "\n\nInstalling the Nagios Plug-ins...."			
			sleep 2
			cd nagios-plugins-1.4.15
			#./configure --sysconfdir=/etc/nagios --localstatedir=/var/nagios --enable-perl-modules
			./configure --with-nagios-user=nagios --with-nagios-group=nagios
			sleep 1
			make clean 
			make
			make install
			chown nagios.nagios /usr/local/nagios
			chown -R nagios.nagios /usr/local/nagios/libexec
			
			echo -e "\n\nInstalling the NRPE...."
			cd ../nrpe-2.12
			./configure
			make all
			make install-plugin
			make install-daemon
			make install-daemon-config
			make install-xinetd

			if [ -e  /etc/xinetd.d/nrpe ];
			then
			    sed "/only_from/s/$/ $SERVER_IP/g" /etc/xinetd.d/nrpe > /etc/xinetd.d/temp.txt; mv /etc/xinetd.d/temp.txt /etc/xinetd.d/nrpe
			fi
			if [ -e  /usr/local/nagios/etc/nrpe.cfg ];
			then
			  echo "command[check_disk]=/usr/local/nagios/libexec/check_disk -w 20% -c 10% -p /dev/sda1" >> /usr/local/nagios/etc/nrpe.cfg
			  echo "command[check_procs]=/usr/local/nagios/libexec/check_procs -w 150 -c 200" >> /usr/local/nagios/etc/nrpe.cfg
			  echo "command[check_swap]=/usr/local/nagios/libexec/check_swap -w 15% -c 7%" >> /usr/local/nagios/etc/nrpe.cfg
			fi
			chmod a+x /etc/xinetd.d/nrpe
			echo -e "\nnrpe 5666/tcp # NRPE" >> /etc/services
			/etc/init.d/xinetd restart
			netstat -at | grep nrpe
			echo -e "\n\nNagios Client Installation is finished !!!!"		
			# Config file modification
			Nag_config_modify
			##### END Nagios #####
    			
    			##### Cacti Agent #####
			apt-get -y --force-yes install make gcc g++ build-essential ftp ncftp
			apt-get -y --force-yes install openssl libssl-dev
     			apt-get -y --force-yes install snmp snmpd
			cp /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.original
			echo -e "# Allow Systems Management Data Engine SNMP to connect to snmpd using SMUX\nsmuxpeer .1.3.6.1.4.1.674.10892.1" >> /etc/snmp/snmpd.conf
			if [ -e /etc/default/snmpd ];
			then 
				echo -e "\tModifying SNMPD binds to all.\n"
				sed -e "s/ 127.0.0.1//g" /etc/default/snmpd > temp.txt; mv temp.txt /etc/default/snmpd
			fi
			
			if [ -e /etc/snmp/snmpd.conf ]; 
			then
				sed -e "s/view.*system.*included.*.1.3.6.1.2.1.1/view system included  .iso.org.dod.internet.mgmt.mib-2.system/" /etc/snmp/snmpd.conf > temp.txt; mv temp.txt /etc/snmp/snmpd.conf
				sed -e "s/com2sec.*paranoid.*default.*$/com2sec readonly default public/" /etc/snmp/snmpd.conf > temp.txt; mv temp.txt /etc/snmp/snmpd.conf					
				sleep 2
			fi
			sudo /etc/init.d/snmpd restart
			# CACTI Config file modification
			Cacti_config_modify
			#### END Cati Agent #####    
           ;;
     Red)
    			welcome_msg    
			sleep 2
			# Nagios Client install
    			install_Nagios
			# Config file modification
			Nag_config_modify
			# END of Nagios
			sleep 3
			# Cacti Client Install
    			install_Cacti
			# CACTI Config file modification
			Cacti_config_modify
			#### END Cati Agent #####    
           ;;

     Fedora)
    			welcome_msg    
			sleep 2
			# Nagios Client install
    			install_Nagios
			# Config file modification
			Nag_config_modify
			# END of Nagios
			sleep 3
			# Cacti Client Install
    			install_Cacti
			# CACTI Config file modification
			Cacti_config_modify
			#### END Cati Agent #####   
           ;;
     *)
          	echo -e "\n\t${txtred}${txtbld}###### WARNING ######${txtrst}"
           	echo -e "\n\t${txtylw}${txtbld}This Script must be executed on${txtrst} ${txtcyn}${txtbld}Ubuntu/Fedora/CentOS/RedHat${txtrst} ${txtylw}${txtbld}Flavor's Only.${txtrst}\n"
           	exit 1
           ;;
esac            
fi
##############  END of Script ############
