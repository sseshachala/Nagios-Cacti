#!/bin/bash
# Run this Script every 5 min on CACTI SERVER.
# Format should be : HOSTNAME:<IP-Addr>:<Description>

DB_user="cacti"		# DO NOT CHANGE
DB_psw="flexi"		# Change if require

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

while read line
do
 IP=`echo -e "$line" | grep "HOSTNAME" | awk -F: '{print $2}'`
 DESC=`echo -e "$line" | grep "HOSTNAME" | awk -F: '{print $3}'`
 #IP="192.168.1.90"
 #DESC="Print90"
 # Add a New Device
 /usr/bin/php -q /usr/share/cacti/cli/add_device.php --description="$DESC" --ip=$IP --template=3  --avail=snmp --community="public" --version=1
 # To get Host Id's
 ID=`/usr/bin/php -q /usr/share/cacti/cli/add_data_query.php --list-hosts | grep "$DESC" | sed 's/\t/,/g' | awk -F, '{print $1}'`
######### Data Query [SNMP - Interface Statistics]  #####
#Ethernet=`/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --snmp-field=ifType --list-snmp-values | grep -v "Known" | grep -v "softwareLoopback"`
#Ethernet=`/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --snmp-field=ifType --list-snmp-values | grep "ethernetCsmacd"`
#for a in $Ethernet
#do
/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=ds --graph-template-id=2 --snmp-query-id=1 --snmp-query-type-id=13 --snmp-field=ifOperStatus --snmp-value=Up
#done
/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=cg --graph-template-id=4
/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=cg --graph-template-id=7
/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=cg --graph-template-id=8
/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=cg --graph-template-id=9
/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=cg --graph-template-id=10
#/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=cg --graph-template-id=11
/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=cg --graph-template-id=12
/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=cg --graph-template-id=13
#/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=cg --graph-template-id=21
######### Data Query [Unix - Get Mounted Partitions] #####
Disk=`/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --snmp-field=dskDevice --list-snmp-values | grep -v "Known"`
for i in $Disk
do
	/usr/bin/php php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=ds --graph-template-id=21 --snmp-query-id=6 --snmp-query-type-id=15 --snmp-field=dskDevice --snmp-value=$i
done
##### Processor
#Proc=`/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --snmp-field=hrProcessorFrwID --list-snmp-values | grep -v "Known"`
#for j in $Proc
#do
#	/usr/bin/php -q /usr/share/cacti/cli/add_graphs.php --host-id=$ID --graph-type=ds --graph-template-id= --snmp-query-id=9 --snmp-query-type-id=19 --snmp-field=hrProcessorFrwID --snmp-value=$j
#done
#php -q add_tree.php --list-trees
SUB="[Cacti Alert] Host: $IP has been added on Cacti Server."
mailID="support@hudooku.com"
dbase=`mysql -u$DB_user -p$DB_psw -e"use cacti; select host_id from graph_tree_items where host_id =$ID;"`
res=`echo $dbase | awk '{print $2}'`
if [ "$res" != "$ID" ];
then
/usr/bin/php -q /usr/share/cacti/cli/add_tree.php --type=node --node-type=host --tree-id=1 --host-id=$ID
echo -e "Click on \"devices\" and Select the latest Device updated recently.\nNow please Click on \"Create Graphs for this Host\".\n\nSelect the Index or templates from the following tables:\n
\tGraph Templates\n\tData Query [SNMP - Get Mounted Partitions] \n\tData Query [SNMP - Get Processor Information] \n\tData Query [SNMP - Interface Statistics] \n\tData Query [Unix - Get Mounted Partitions] \n
\n\nThis is an automatically generated mail by Cacti Sever, Please DO NOT REPLAY to this eMail ID." | mutt -s "$SUB" $mailID
else
echo -e "\nAlready Graph Tree Exists fo this Host\n"
fi
done </usr/share/cacti/cacti_clients
# Restart to effect the changes.
#/etc/init.d/nagios reload
# END #