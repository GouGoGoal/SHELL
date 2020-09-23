#!/bin/bash
#创建和物理内存大小一直的交换分区，路径为 /swap，并实现开机自动挂载
#适合某些模板开机的系统没有swap分区，增加系统稳定性


if [ "$UID" != "0" ];then 
	echo "请以root用户执行"
fi

if [ -f "/swap" ];then 
	echo "/swap 已存在"
	exit 0
fi
if [ "`free -h|grep Swap|awk '{print $2}'`" != "0B" ];then 
	echo "当前已存在`free -h|grep Swap|awk '{print $2}'`的swap，确定还要继续增加吗"
	read -n 1 -s -r -p "按任意键继续，CTRL+C取消"
fi

if [ "$1" = "" ];then
	memory=`free -m|grep Mem|awk '{print $2}'`
fi
if [ "`df -m |grep -w '/' |awk '{printf $4}'`"  -lt "$memory" ];then 
	echo "当前根分区空间不足" 
	exit 0
else
	echo "正在创建分区文件，请耐心等待"
	dd if=/dev/zero of=/swap bs=1M count=$memory
	mkswap /swap
	chmod 600 /swap
	swapon /swap
	echo '/swap swap swap defaults 0 0'>>/etc/fstab
	echo "添加完毕"
fi
