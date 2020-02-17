#!/bin/bash
#author Kevin MULLER https://github.com/kiki67100/iptables-block-tor-network


if [ "$USER" != "root" ]; then
    echo "[!] Must be run as root (you are $USER)."
    exit 1
fi

if ! which ipset >/dev/null;then
	echo "[!] required ipset";
	exit;
fi;
#exit;
INTERFACE="em1"; #change with your interface
CHAIN_NAME="TOR_BLOCK"
CHAIN_LOG=${CHAIN_NAME}_LOG;
TMP_TOR_LIST="/tmp/temp_tor_list"
IP_ADDRESS=$(ifconfig $INTERFACE | awk '/inet addr/ {split ($2,A,":"); print A[2]}')
PORT="80 22 443 21"

if [ -z "$IP_ADDRESS" ];then
    echo "[!] Impossible to get your IP from interface $INTERFACE . Change your interface?";
    exit 1;
fi;

/sbin/iptables -n -v -L INPUT --line-number|grep $CHAIN_NAME|while read line;do
	num_rule=$(echo $line|cut -d ' ' -f1);
	echo "[+] Remove old INPUT ENTRY $num_rule";
	/sbin/iptables -D INPUT $num_rule;
done;

/sbin/iptables -F $CHAIN_NAME 2>/dev/null;
/sbin/iptables -X $CHAIN_NAME 2>/dev/null;
/sbin/ipset destroy $CHAIN_NAME 2>/dev/null;

if ! /sbin/iptables -n -L $CHAIN_NAME 2>/dev/null | grep  $CHAIN_NAME;then
                echo "[+] Create $CHAIN_NAME";
		/sbin/iptables -N $CHAIN_NAME;
		#/sbin/iptables -A $CHAIN_NAME -j ACCEPT;
		echo "[+] Create ipset iphash $CHAIN_NAME";
		/sbin/ipset -N $CHAIN_NAME iphash;	
fi

echo "[+] FLUSH ipset $CHAIN_NAME";
/sbin/ipset flush $CHAIN_NAME;
echo "[+] FLUSH $CHAIN_NAME";
/sbin/iptables -F $CHAIN_NAME;


echo "[+] Public ip : $IP_ADDRESS";

rm -f $TMP_TOR_LIST
touch $TMP_TOR_LIST

echo "[+] Get exit node ips list from check.torproject.org";
for P in $PORT;do
	echo "	[+] for port $P";
	/usr/bin/wget -q -O - "https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=$IP_ADDRESS&port=$P" -U NoSuchBrowser/1.0 >> $TMP_TOR_LIST
done
sed -i 's|^#.*$||g' $TMP_TOR_LIST


for IP in $(cat $TMP_TOR_LIST | sort|uniq)
do
	/sbin/ipset add $CHAIN_NAME $IP;
done;


/sbin/iptables -A $CHAIN_NAME -m set --match-set $CHAIN_NAME src -j LOG --log-prefix "TOR_BLOCK:" --log-level 6
/sbin/iptables -A $CHAIN_NAME -m set --match-set $CHAIN_NAME src -j DROP ;
/sbin/iptables -A INPUT -j $CHAIN_NAME;
#iptables -A $CHAIN_NAME -j DROP

/sbin/iptables-save >> /var/log/block-tor-iptables.log
