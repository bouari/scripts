#! /bin/bash

quisuisje=$(whoami)
if [ $quisuisje != "root" -a $(sudo -l | grep -c "(ALL) NOPASSWD: ALL") -eq 0 ]
then
	echo -e "\033[33mTu n'as pas les permissions pour execter ce programme\033[0m "
	exit1 
else
	USER=$(who am i | awk '{print $1}')
	HOMEUSER=$(getent passwd boualem.ouari | awk -F: '{ print $6 }')
fi

scriptexec=$(basename "$0")

suffix=""

[ "$scriptexec" == "sanitycheck-beforemep.sh" ] && suffix="beforemep"
[ "$scriptexec" == "sanitycheck-aftermep.sh" ] && suffix="aftermep"
[ -z "$suffix" ] && exit 1

if [ "$scriptexec" == "sanitycheck-aftermep.sh" ]
then
	if [ ! -d $HOMEUSER/MEP_`date +"%Y%m%d"` -o $(find $HOMEUSER/MEP_`date +"%Y%m%d"` -name "*_beforemep" 2>/dev/null | wc -l) -eq 0 ]
	then
		echo -e "\033[31mNo inventory found\033[0m\n"
		exit 1
	fi
fi

[ ! -d $HOMEUSER/MEP_`date +"%Y%m%d"` ] && mkdir $HOMEUSER/MEP_`date +"%Y%m%d"`

cd $HOMEUSER/MEP_`date +"%Y%m%d"` || exit 1

bold=$(tput bold)
normal=$(tput sgr0)
COLS=$(tput cols)
tabs 4

function display_lines {
	for ligne in $(echo -n "$1")
	do
		echo -e "\t\033[33m$ligne\033[0m "
	done	
} 

function display_banner {
        tput bold
        printf "\e[37;44;93m%*s \033[0m\n" $(tput cols) "Tests de non-regression  |  Copyright © Bell Canada - Boualem Ouari, Juin 2017"
}

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
        systemctl list-units --type service --all 2>/dev/null
else
        for i in $(chkconfig --list | grep ^[aA-zZ] | grep -v "Makefile" | awk '{ print $1 }' )
        do
                RESULT=$(/etc/init.d/$i status 2>/dev/null)
                STATUS=$(echo $RESULT|grep -c "running")
                if [ "$STATUS" -ne 0 ]
                then
	                echo -e "$i \033[32mis running\033[0m"
                else
                        echo -e "$i \033[31mis not running\033[0m"
                fi
        done

fi > stdr-services-status_${suffix}

## Traitements speciaux

# Nimsoft

NIMSOFT=$(ps -ef | grep -c "[n]imbus")

if [ "$NIMSOFT" -gt 0 ]
then
        echo -e "nimbus \033[32mis running\033[0m" >> stdr-services-status_${suffix}
else
        ##echo -e "\033[31Attention nimsof mis not running\033[0m"
        echo -e "nimbus \033[31mis not running\033[0m" >> stdr-services-status_${suffix}
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

iptables-save > iptables-save_${suffix}

netstat -lnpu | tail -n +3 | awk '{ print $1,$4,$5,$6 }' | sed -r -e 's| [0-9]+/| |' -e 's/[[:space:]]+/ /g'  > netstat-lnptu_${suffix}
netstat -lnpt | tail -n +3 | awk '{ print $1,$4,$5,$7 }' | sed -r -e 's| [0-9]+/| |' -e 's/[[:space:]]+/ /g'  >> netstat-lnptu_${suffix}

# Prendre l'état des filesystems
df -hTP -x tmpfs -x devtmpfs | awk '{ print $1,$2,$3,$7 }' > mountedfs_${suffix}

## Les process
##ps -ef | egrep -v "\[.*\]" | awk '{ print $1,$8 }' | egrep -v "bash"  > ps-ef_${suffix}
ps -eo 'tty,user,comm' | grep ^? | grep -v [k]worker | awk '{ print $2,$3 }' > ps-ef_${suffix}

if [ "$scriptexec" == "sanitycheck-beforemep.sh" -a $(find ./ -name "*_beforemep" | wc -l) -ge 8 ]
then
	echo -e "\033[32mThe invetory is taken\033[0m"
fi


if [ "$scriptexec" == "sanitycheck-aftermep.sh" ]
then
	IFS=$'\n'

	display_banner

    echo -e "\e[4;34m${bold}1) Services\033[0m"
	if [ $(grep -cvxFf stdr-services-status_beforemep stdr-services-status_aftermep) -eq 0 ]
	then
		echo -e "\t\033[32mEverything is OK  \033[0m " 
	else
		echo  -e "\e[101mSomething is wrong\033[0m"
		echo
        	RES=$(grep -vxFf stdr-services-status_beforemep stdr-services-status_aftermep)
		echo -e "\033[31m$RES\033[0m "
	fi
    echo

    echo -e "\e[4;34m${bold}2) Network interfaces\033[0m"
	if [ $(grep -cvxFf ipa_beforemep ipa_aftermep) -eq 0 -a $(grep -cvxFf ipa_aftermep ipa_beforemep) -eq 0 ]
	then
		echo -e "\t\033[32mEverything is OK  \033[0m " 
	else
		echo  -e "\e[101mSomething is wrong\033[0m"
		echo
		RES=$(grep -vxFf ipa_beforemep ipa_aftermep)
		RES1=$(grep -vxFf ipa_aftermep ipa_beforemep)
		echo -e "\033[31m$RES\033[0m "
		echo  -e "\033[31;5;7m\nIt was\033[0m"
		echo -e "\033[33m$RES1\033[0m "
	fi
    echo

    echo -e "\e[4;34m${bold}3) Routes\033[0m"
	if [ $(grep -cvxFf ipr_beforemep ipr_aftermep) -eq 0 -a $(grep -cvxFf ipr_aftermep ipr_beforemep) -eq 0 ]
	then
		echo -e "\t\033[32mEverything is OK  \033[0m " 
	else
		echo  -e "\e[101mSomething is wrong\033[0m"
		echo
		if [ $(grep -cvxFf ipr_beforemep ipr_aftermep) -ne 0 ]
		then
			echo -e "\t\033[31mUnexpected routes:\033[0m "
			RES=$(grep -vxFf ipr_beforemep ipr_aftermep)
			display_lines "$RES"
			echo ""
		fi
		if [ $(grep -cvxFf ipr_aftermep ipr_beforemep) -ne 0 ]
		then
			echo -e "\t\033[31mMissing routes:\033[0m "
			RES1=$(grep -vxFf ipr_aftermep ipr_beforemep)
			display_lines "$RES1"
			echo ""
		fi
	fi
    echo

    echo -e "\e[4;34m${bold}4) Firewall (local)\033[0m"
    echo

    echo -e "\e[4;34m${bold}5) Netstat\033[0m"
	if [ $(grep -cvxFf netstat-lnptu_aftermep netstat-lnptu_beforemep) -eq 0 ]
	then
		echo -e "\t\033[32mEverything is OK  \033[0m "
	else
		echo  -e "\e[101mSomething is wrong\033[0m"
		echo
		echo -e "\t\033[31mMissing tcp/udp sockets:\033[0m "
		RES=$(grep -vxFf netstat-lnptu_aftermep netstat-lnptu_beforemep)
		echo -e "\tProto Local_address Foreign_address Program_name"
		display_lines "$RES"
		echo ""
	fi
    echo

    echo -e "\e[4;34m${bold}6) Filesystems\033[0m"	
	if [ $(grep -cvxFf mountedfs_aftermep mountedfs_beforemep) -eq 0 ]
	then
		echo -e "\t\033[32mEverything is OK  \033[0m "
	else
		echo  -e "\e[101mSomething is wrong\033[0m"
		echo
		echo -e "\t\033[31mMissing filesystem:\033[0m"
		echo -e "\tFilesystem Type Size Mount_point"
		RES=$(grep -vxFf mountedfs_aftermep mountedfs_beforemep)
		display_lines "$RES"
		echo ""
	fi
    echo

	echo -e "\e[4;34m${bold}7) Snapshot of the processes\033[0m"
	if [ $(grep -cvxFf ps-ef_aftermep ps-ef_beforemep) -eq 0 ]
        then
                echo -e "\t\033[32mEverything is OK  \033[0m "
        else
		echo  -e "\e[101mSomething is wrong\033[0m"
		echo
        echo -e "\t\033[31mMissing processes:\033[0m"
		RES=$(grep -vxFf ps-ef_aftermep ps-ef_beforemep)
        echo -e "\tUID CMD"
        display_lines "$RES"
        echo ""
	fi
	
fi
echo
display_banner
