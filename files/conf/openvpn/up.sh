#!/bin/sh

/sbin/iptables -F
/sbin/iptables -F -t nat
/sbin/iptables -A FORWARD -o tun0 -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j MASQUERADE



