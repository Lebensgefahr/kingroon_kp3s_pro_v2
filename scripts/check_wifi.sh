#!/bin/bash

ip link set dev wlan0 down

MODULE="$(lsmod|awk '{if($1 ~ "8723bs") print $1}')"

case $MODULE in
  r8723bs)
    rmmod r8723bs &&
#    insmod /root/rockchip_wlan/rtl8723bs/8723bs.ko
    modprobe 8723bs &&
    echo "8723bs.ko module loaded"
  ;;
  8723bs)
    rmmod 8723bs &&
    modprobe r8723bs &&
    echo "r8723bs module loaded"
  ;;
esac

ip link set dev wlan0 up &&
sleep 4 &&
ip add add 192.168.1.15/24 dev wlan0 &&
ip route add default via 192.168.1.1 &&

curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 - |grep 'Upload\|Download'
