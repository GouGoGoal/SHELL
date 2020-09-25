#!/bin/bash
#旨在解决nginx转发动态域名时不会自动更新，以及缓解域名过多时出现的解析失败的现象
#使用此脚本旧不要在nginx里使用resolver参数了，并按下方命令添加计划任务
#echo "* * * * * root flock -xn /dev/shm/hosts.lock -c 'bash /etc/nginx/nginx_helper.sh'">>/etc/crontab
#不设置则使用系统DNS
#DNS=223.5.5.5

#工作目录放至共享内存
workdir="/dev/shm"

domain=(
	#填写域名，注意分号
	"www.baidu.com"
)

#备份原hosts
if [ ! -f "/etc/hosts.bak" ];then 
	cp /etc/hosts /etc/hosts.bak
fi

#检测是否有host指令，如果没有就装一下
if [ "`command -v host`" == "" ]; then
    echo "host命令安装中。。。"
    if [ ! -f "/etc/redhat-release" ]; then
        apt install -y dnsutils
    else 
	yum install -y bind-utils
    fi
fi

#删除可能遗留的缓存
rm -rf "$workdir"/hosts.change
rm -rf "$workdir"/hosts
rm -rf "$workdir"/hosts.tmp

#将现有hosts拷贝至共享内存
`which cp|tail -1` -f /etc/hosts "$workdir"/hosts

if [ "$DNS" == "" ];then
	for rule in ${domain[@]}
	do
		{
		ip=`host $rule|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`
		if [ "$ip" != "" ];then 
			echo "$ip $rule">>"$workdir"/hosts.tmp
			if [ "`grep $ip "$workdir"/hosts`" == "" ];then 
				touch "$workdir"/hosts.changed
			fi
		fi
		}&
	done
else 

	for rule in ${domain[@]}
	do
		{
		ip=`host $rule $DNS|grep -v $DNS|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`
		if [ "$ip" != "" ];then 
			echo "$ip $rule">>"$workdir"/hosts.tmp
			if [ "`grep $ip "$workdir"/hosts`" == "" ];then 
				echo "1" >"$workdir"/hosts.changed
			fi
		else continue
		fi
		}&
	done
fi
#等待全部判断完成
wait

if [ -f ""$workdir"/hosts.changed" ];then 
	`which cp|tail -1` -f /etc/hosts.bak /etc/hosts
	cat "$workdir"/hosts.tmp >>/etc/hosts
	systemctl reload nginx
fi

#删除缓存
rm -rf "$workdir"/hosts.changed
rm -rf "$workdir"/hosts
rm -rf "$workdir"/hosts.tmp
