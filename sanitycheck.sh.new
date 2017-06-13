#! /bin/bash
#
# Tests de non-regression (sanitycheck.sh)
# Version: 1.0
# Author:  Copyright © Bell Canada - Boualem Ouari <boualem.ouari@bell.ca>, Juin 2017
#
# TODO:
# Changer beforemep pour inventory 
#	  aftermep pour verif
# verif doit aussi pouvoir comparer à la ref
#

if [ $(uname) != "Linux" ]
then
	echo -e "\033[33mThis OS is not supported\033[0m"
	exit 1
fi

quisuisje=$(whoami)
if [ $quisuisje != "root" ]
then
	echo -e "\033[33mTu n'as pas les permissions pour executer ce programme\033[0m "
	exit1 
fi

HOMEUSER="/home/das_sysadmin"

scriptexec=$(basename "$0")

suffix=""
MonitoringName="Nimsoft"
MonitoringProc="nimbus"

bold=$(tput bold)
normal=$(tput sgr0)
COLS=$(tput cols)
TC_RESET=$'\e[0m'
TC_WITHE=$'\e[0;107;31m'
#TC_WITHE=$'\e[0;47;31m'
TC_GREEN=$'\e[0;42;30m'
NBR_INV_FILE=7
<<<<<<< HEAD
WorkingDir=MEP_`date +"%Y%m%d%H"`
SameWorkingDir=MEP_`date -d "-4 hours" +"%Y%m%d%H"`
WorkingDirChange="no"
=======
#
echo "$COLS"
>>>>>>> 7fdb261c506e562416f77b540e39ae0625027f3e

if [ "$scriptexec" == "sanitycheck-ref.sh" ]
then
	WorkingDir=REF_`date +"%Y%m%d%H"`
	SameWorkingDir=REF_`date -d "-4 hours" +"%Y%m%d%H"`
fi

function display_lines {
	for ligne in $(echo -n "$1")
	do
		echo -e "\t\033[33m$ligne\033[0m "
	done	
} 

function display_banner {
        # tput bold
        printf "\e[37;44;93m%*s\033[0m" $COLS "Tests de non-regression  |  Copyright © Bell Canada - Boualem Ouari, Juin 2017"
}

center() {
  padding="$(printf '%0.1s' \ {1..500})"
  printf '%*.*s %s %*.*s' 0 "$(((COLS-2-${#1})/2))" "$padding" "$1" 0 "$(((COLS-1-${#1})/2))" "$padding"
}

[ "$scriptexec" == "sanitycheck-beforemep.sh" ] && suffix="beforemep"
[ "$scriptexec" == "sanitycheck-aftermep.sh" ] && suffix="aftermep"
[ "$scriptexec" == "sanitycheck-afterreboot.sh" ] && suffix="afterreboot"
[ "$scriptexec" == "sanitycheck-ref.sh" ] && suffix="ref"


if [ -z "$suffix" ] 
then
	echo
	display_banner
	echo -e "\e[34m${bold}Usage:\033[0m"
	printf "\t\e[32m%-27s\033[0m : %-80s\n" "sanitycheck-beforemep.sh" "For taking inventory before making change or rebooting"
	printf "\t\e[32m%-27s\033[0m : %-80s\n" "sanitycheck-afterreboot.sh" "After rebooting without making changes"
	printf "\t\e[32m%-27s\033[0m : %-80s\n" "sanitycheck-aftermep.sh" "After making change and rebooting"
	printf "\t\e[32m%-27s\033[0m : %-80s\n" "sanitycheck-ref.sh" "To make reference"
	exit 1
fi

if [ "$scriptexec" == "sanitycheck-aftermep.sh" -o "$scriptexec" == "sanitycheck-afterreboot.sh" ]
then
	if [ -d $HOMEUSER/$WorkingDir ]
	then
		if [ $(find $HOMEUSER/$WorkingDir/ -name "*_beforemep" 2>/dev/null | wc -l) -lt $NBR_INV_FILE ]
		then
			echo -e "\033[31mNo inventory found code1\033[0m\n"
			exit 1
		fi
	else
		if [ -d $HOMEUSER/$SameWorkingDir ] 
		then
			##cd $HOMEUSER && ln -s $SameWorkingDir $WorkingDir 
			WorkingDir=$SameWorkingDir
			WorkingDirChange="yes"
		fi
		if [ $(find $HOMEUSER/$SameWorkingDir/ -name "*_beforemep" 2>/dev/null | wc -l) -lt $NBR_INV_FILE ]
		then
			echo -e "\033[31mNo inventory found code2\033[0m\n"
			exit 1
		fi	
	fi
fi

if [ "$scriptexec" == "sanitycheck-beforemep.sh" -o "$scriptexec" == "sanitycheck-ref.sh" ]
then
	[ ! -d $HOMEUSER/$WorkingDir ] && mkdir -p $HOMEUSER/$WorkingDir
	[ "$scriptexec" == "sanitycheck-ref.sh" ] && cd $HOMEUSER && ln -sfn $WorkingDir REF
fi

cd $HOMEUSER/$WorkingDir || exit 1


if [ "$scriptexec" == "sanitycheck-beforemep.sh" ]
then
        if [ $(find ./ -name "*_beforemep" | wc -l) -gt 0 ]
        then
                echo -e "\033[31mScript $scriptexec is already executed\033[0m\n"
                exit 1
        fi
fi

## Liste des service running

#if grep --quiet "Red Hat Enterprise Linux Server release 7" /etc/*-release
if grep --quiet "release 7" /etc/*-release
then
        ##systemctl list-units --type service | grep running
        systemctl list-units --type service --all 2>/dev/null | grep -v "loaded units listed."
else
        for i in $(chkconfig --list | grep "^[[:alpha:]]" | grep -v "Makefile" | awk '{ print $1 }' )
        do
                RESULT=$(/etc/init.d/$i status 2>/dev/null)
                STATUS=$(echo $RESULT|grep -c "running")
                if [ "$STATUS" -ne 0 ]
                then
	                echo -e "\033[32${i}mis running\033[0m"
                else
                        echo -e "\033[31${i}mis not running\033[0m"
                fi
        done

fi > stdr-services-status_${suffix}

## Traitements speciaux

# Nimsoft

MONITPROC=$(ps -ef | grep -v grep | grep -c "${MonitoringProc}")

display_banner
echo
if [ "$MONITPROC" -gt 0 ]
then
        echo -e "$MonitoringProc \033[32mis running\033[0m" >> stdr-services-status_${suffix}
else
	echo -n "${TC_WITHE}"
	mess="$MonitoringName is not running"
	center "Warning"
	center "$mess"
	echo ${TC_RESET}

        echo -e "$MonitoringProc \033[31mis not running\033[0m" >> stdr-services-status_${suffix}
fi


## Prendre les versions des package avant la MEP
rpm -qa > rpm-qa_${suffix}

## Prendre la configuration réseau "live"

for interface in $(cat /proc/net/dev | egrep -v "\||lo:" | awk -F: '{ print $1 }' )
do 
	ip addr show $interface | egrep "$interface|link|inet|inet6" | tr -d "\n" | sed -r 's/^[0-9]+: //'
	echo ""
done > ipa_${suffix}

ip r > ipr_${suffix}

iptables-save | sed -r 's/\[[0-9]+:[0-9]+\]/\[0:0\]/g' | grep -v "^#" > iptables-save_${suffix}
## Certains daemons ecoutent sur des ports supplementaire aleatoires. 
prog_randome_port="dhclient|rpcbind"
if [ -s /etc/oratab ] 
then
	oracle_sids=$(egrep -v "^#|^$" /etc/oratab|awk -F: '{ print $1 }'| tr "\n" "|" | sed 's/|$//')
	oracle_sids_short=$(egrep -v "^#|^$" /etc/oratab|awk -F: '{ print $1 }'| sed -r 's|(....).*|\1|' | tr "\n" "|" | sed 's/|$//')
	netstat -lnpu | egrep -v "$prog_randome_port" | tail -n +3 | awk '{ print $1,$4,$5,$6 }' | sed -r -e 's| [0-9]+/| |' -e 's/[[:space:]]+/ /g' | egrep -v "oracle|$oracle_sids|$oracle_sids_short" | sed -r 's/$MonitoringName\(.*/$MonitoringName/' |  grep -v "cmahostd" | sort | uniq  > netstat-lnptu_${suffix}
	netstat -lnpt | egrep -v "$prog_randome_port" | tail -n +3 | awk '{ print $1,$4,$5,$7 }' | sed -r -e 's| [0-9]+/| |' -e 's/[[:space:]]+/ /g' | egrep -v "oracle|$oracle_sids|$oracle_sids_short" | sed -r 's/$MonitoringName\(.*/$MonitoringName/' |grep -v "cmahostd" | sort | uniq >> netstat-lnptu_${suffix}
else
	netstat -lnpu | egrep -v "$prog_randome_port" | tail -n +3 | awk '{ print $1,$4,$5,$6 }' | sed -r -e 's| [0-9]+/| |' -e 's/[[:space:]]+/ /g' | sed -r 's/$MonitoringName\(.*/$MonitoringName/'| grep -v "cmahostd" | sort | uniq  > netstat-lnptu_${suffix}
	netstat -lnpt | egrep -v "$prog_randome_port" | tail -n +3 | awk '{ print $1,$4,$5,$7 }' | sed -r -e 's| [0-9]+/| |' -e 's/[[:space:]]+/ /g' | sed -r 's/$MonitoringName\(.*/$MonitoringName/'| grep -v "cmahostd" | sort | uniq >> netstat-lnptu_${suffix}
fi

# Prendre l'état des filesystems
df -hTP -x tmpfs -x devtmpfs | awk '{ print $1,$2,$3,$7 }' > mountedfs_${suffix}

## Les process
##ps --ppid 2 -p 2 --deselect -o 'tty,user,comm' | grep ^? |  awk '{ print $2,$3 }' | sort | uniq > ps-ef_${suffix}
ps --ppid 1 -o 'tty,user,comm' | grep ^? |  awk '{ print $2,$3 }' | sort | uniq > ps-ef_${suffix}

if [ "$scriptexec" == "sanitycheck-beforemep.sh" -a $(find ./ -name "*_beforemep" | wc -l) -gt $NBR_INV_FILE ]
then
	find ./ -name "*_beforemep" -exec chattr +i {} \;
	echo -e "\033[32mThe inventory has been taken and protected\033[0m"
fi

if [ "$scriptexec" == "sanitycheck-aftermep.sh" -o "$scriptexec" == "sanitycheck-afterreboot.sh" ]
then
	IFS=$'\n'

	###if [ -L $HOMEUSER/$WorkingDir ]
	if [ $WorkingDirChange == "yes" ]
	then
		echo -n "${TC_GREEN}"
<<<<<<< HEAD
		center "Your inventory is $SameWorkingDir"
		echo ${TC_RESET}
=======
		center "Your inventory is $(ls -l $HOMEUSER/MEP_`date +"%Y%m%d"` | sed 's|^.*/||g')"
>>>>>>> 7fdb261c506e562416f77b540e39ae0625027f3e
	fi
	printf "\e[100m%-*s\033[0m\n" $((($COLS)/5)) "1) Services"
	if [ $(grep -cvxFf stdr-services-status_beforemep stdr-services-status_${suffix}) -eq 0 -a $MONITPROC -ne 0 ]
	then
		echo -e "\t\033[32mEverything is OK\033[0m " 
	else
		printf "\e[41m%-*s\033[0m" $((($COLS)/5)) "Something is wrong"
		echo
		### [ $MONITPROC -eq 0 ] && echo -e "\033[31m  $MonitoringName is not running\033[0m"
		[ $MONITPROC -eq 0 ] && echo -e "\033[31m  $(grep [n]imbus stdr-services-status_${suffix})"
		if [ $(grep -cvxFf stdr-services-status_beforemep stdr-services-status_${suffix}) -ne 0 ]
		then
        		RES=$(grep -vxFf stdr-services-status_beforemep stdr-services-status_${suffix})
			echo -e "\033[31m$RES\033[0m "
		fi
	fi
	echo ${TC_RESET}
    	##echo

	printf "\e[100m%-*s\033[0m\n" $((($COLS)/5)) "2) Network interfaces"
	if [ $(grep -cvxFf ipa_beforemep ipa_${suffix}) -eq 0 -a $(grep -cvxFf ipa_${suffix} ipa_beforemep) -eq 0 ]
	then
		#echo -e ${TC_RESET}
		echo -e "\t\033[32mEverything is OK\033[0m" 
	else
		printf "\e[41m%-*s\033[0m" $((($COLS)/5)) "Something is wrong"
		echo
		RES=$(grep -vxFf ipa_beforemep ipa_${suffix})
		RES1=$(grep -vxFf ipa_${suffix} ipa_beforemep)
		echo -e "\033[31m$RES\033[0m "
		echo  -e "\033[31;5;7m\nIt was\033[0m"
		echo -e "\033[33m$RES1\033[0m "
	fi
    	echo

	printf "\e[100m%-*s\033[0m\n" $((($COLS)/5)) "3) Routes"
	if [ $(grep -cvxFf ipr_beforemep ipr_${suffix}) -eq 0 -a $(grep -cvxFf ipr_${suffix} ipr_beforemep) -eq 0 ]
	then
		echo -e "\t\033[32mEverything is OK  \033[0m " 
	else
		printf "\e[41m%-*s\033[0m" $((($COLS)/5)) "Something is wrong"
		echo
		if [ $(grep -cvxFf ipr_${suffix} ipr_beforemep) -ne 0 ]
		then
			echo -e "\t\033[31mMissing routes:\033[0m "
			RES1=$(grep -vxFf ipr_${suffix} ipr_beforemep)
			display_lines "$RES1"
			echo ""
		fi
		if [ $(grep -cvxFf ipr_beforemep ipr_${suffix}) -ne 0 ]
		then
			echo -e "\t\033[31mUnexpected routes:\033[0m "
			RES=$(grep -vxFf ipr_beforemep ipr_${suffix})
			display_lines "$RES"
			echo ""
		fi
	fi
    	echo

	printf "\e[100m%-*s\033[0m\n" $((($COLS)/5)) "4) Firewall (firewalld/iptables)"
        if [ $(grep -cvxFf iptables-save_beforemep iptables-save_${suffix}) -eq 0 -a $(grep -cvxFf iptables-save_${suffix} iptables-save_beforemep) -eq 0 ]
        then
                echo -e "\t\033[32mEverything is OK  \033[0m "
        else
		printf "\e[41m%-*s\033[0m" $((($COLS)/5)) "Something is wrong"
                echo
                if [ $(grep -cvxFf iptables-save_${suffix} iptables-save_beforemep) -ne 0 ]
                then
                        echo -e "\t\033[31mMissing rules:\033[0m "
                        RES1=$(grep -vxFf iptables-save_${suffix} iptables-save_beforemep)
                        display_lines "$RES1"
                        echo ""
                fi
                if [ $(grep -cvxFf iptables-save_beforemep iptables-save_${suffix}) -ne 0 ]
                then
                        echo -e "\t\033[31mUnexpected rules:\033[0m "
                        RES=$(grep -vxFf iptables-save_beforemep iptables-save_${suffix})
                        display_lines "$RES"
                        echo ""
                fi
        fi
    	echo

	printf "\e[100m%-*s\033[0m\n" $((($COLS)/5)) "5) TCP/UDP listening sockets (netstat)"
	if [ $(grep -cvxFf netstat-lnptu_${suffix} netstat-lnptu_beforemep) -eq 0 -a $(grep -cvxFf netstat-lnptu_beforemep netstat-lnptu_${suffix}) -eq 0 ]
	then
		echo -e "\t\033[32mEverything is OK  \033[0m "
	else
		printf "\e[41m%-*s\033[0m" $((($COLS)/5)) "Something is wrong"
		echo
		if [ $(grep -cvxFf netstat-lnptu_${suffix} netstat-lnptu_beforemep) -ne 0 ]
		then
			echo -e "\t\033[31mMissing tcp/udp sockets:\033[0m "
			RES=$(grep -vxFf netstat-lnptu_${suffix} netstat-lnptu_beforemep)
			echo -e "\tProto Local_address Foreign_address Program_name"
			display_lines "$RES"
			echo ""
		fi
		if [ $(grep -cvxFf netstat-lnptu_beforemep netstat-lnptu_${suffix}) -ne 0 ]
		then
			echo -e "\t\033[31mUnexpected tcp/udp sockets:\033[0m "
                        RES1=$(grep -vxFf netstat-lnptu_beforemep netstat-lnptu_${suffix})
                        echo -e "\tProto Local_address Foreign_address Program_name"
                        display_lines "$RES1"
                        echo ""
		fi
	fi
   	echo

	printf "\e[100m%-*s\033[0m\n" $((($COLS)/5)) "6) Filesystems"
	if [ $(grep -cvxFf mountedfs_${suffix} mountedfs_beforemep) -eq 0 -a $(grep -cvxFf mountedfs_beforemep mountedfs_${suffix}) -eq 0 ]
	then
		echo -e "\t\033[32mEverything is OK  \033[0m "
	else
		printf "\e[41m%-*s\033[0m" $((($COLS)/5)) "Something is wrong"
		echo
		if [ $(grep -cvxFf mountedfs_${suffix} mountedfs_beforemep) -ne 0 ]
		then
			echo -e "\t\033[31mMissing filesystems:\033[0m"
			echo -e "\tFilesystem Type Size Mount_point"
			RES=$(grep -vxFf mountedfs_${suffix} mountedfs_beforemep)
			display_lines "$RES"
			echo ""
		fi
		if [ $(grep -cvxFf mountedfs_beforemep mountedfs_${suffix}) -ne 0 ]
		then 
                        echo -e "\t\033[31mUnexpected filesystems:\033[0m"
                        echo -e "\tFilesystem Type Size Mount_point"
                        RES1=$(grep -vxFf mountedfs_beforemep mountedfs_${suffix})
                        display_lines "$RES1"
                        echo ""
                fi
	fi
    	echo

	printf "\e[100m%-*s\033[0m\n" $((($COLS)/5)) "7) Daemons process"
	if [ $(grep -cvxFf ps-ef_${suffix} ps-ef_beforemep) -eq 0 -a $(grep -cvxFf ps-ef_beforemep ps-ef_${suffix}) -eq 0 ]
        then
                echo -e "\t\033[32mEverything is OK  \033[0m "
        else
		printf "\e[41m%-*s\033[0m" $((($COLS)/5)) "Something is wrong"
		echo
		if [ $(grep -cvxFf ps-ef_${suffix} ps-ef_beforemep) -ne 0 ]
		then
	        	echo -e "\t\033[31mMissing processes:\033[0m"
			RES=$(grep -vxFf ps-ef_${suffix} ps-ef_beforemep)
		        echo -e "\tUID CMD"
		        display_lines "$RES"
		        echo ""
		fi
		if [ $(grep -cvxFf ps-ef_beforemep ps-ef_${suffix}) -ne 0 ]
		then
			echo -e "\t\033[31mUnexpected processes:\033[0m"
			RES1=$(grep -vxFf ps-ef_beforemep ps-ef_${suffix})
			echo -e "\tUID CMD"
                        display_lines "$RES1"
                        echo ""
		fi
	fi
	
fi
echo
display_banner
