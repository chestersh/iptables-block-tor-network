# iptables-block-tor-network
Block TOR network using iptables / ipset 

All DROP ips is log TO /var/log/syslog example :

```bash
Feb 17 11:39:28 hostname kernel: [ 6452.863321] TOR_BLOCK:IN=em1 OUT= MAC=d4:FF:50:ca:09:ba:70:b1:01:f0:78:67:08:00 **SRC=23.129.64.205** DST=XX.XX.XX.XX 1 LEN=60 TOS=0x00 PREC=0x00 TTL=55 ID=0 DF PROTO=TCP SPT=43302 **DPT=80** WINDOW=65535 RES=0x00 SYN URGP=0
```
