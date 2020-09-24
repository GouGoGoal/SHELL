#!/bin/bash
#旨在解决nginx转发动态域名时不会自动更新，以及缓解域名过多时出现的解析失败的现象
#使用此脚本旧不要在nginx里使用resolver参数了，并按下方命令添加计划任务
#echo "* * * * * root flock -xn /tmp/hosts.lock -c 'bash /etc/nginx/nginx_helper.sh'">>/etc/crontab
#不设置则使用系统DNS
#DNS=223.5.5.5

domain=( 
	#"填写nginx需要转发的域名"
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
#定义规则是否改变
is_changed=0
#循环检测
i=0
rule=${domain[${i}]}
while [ -n "$rule" ] 
do
	if [ "$DNS" == "" ];then
		ip=`host $rule|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`
	else
		ip=`host $rule $DNS|grep -v $DNS|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`
	fi
	if [ "$ip" != "" ];then 
		echo "$ip $rule">>/tmp/hosts_temp
		if [ "`grep $ip /etc/hosts`" == "" ];then is_changed=1;fi
	else continue
	fi
	let i++
	rule=${domain[${i}]}
done


if [ "$is_changed" == "1" ];then 
	`which cp|tail -1` -f /etc/hosts.bak /etc/hosts
	cat /tmp/hosts_temp >>/etc/hosts
	rm -rf /tmp/hosts_temp
	systemctl reload nginx
else 
	rm -rf /tmp/hosts_temp
fi
