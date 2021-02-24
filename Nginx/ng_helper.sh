#!/bin/bash
#旨在解决nginx转发动态域名时不会自动更新，以及缓解域名过多时出现的解析失败的现象
#若使用此脚本不要在nginx里使用resolver参数，并按下方命令添加计划任务
#echo "* * * * * root flock -xn /dev/shm/hosts.lock -c 'bash /etc/nginx/nginx_helper.sh'">>/etc/crontab

#缓存文件
WorkFile="/dev/shm/nginx_helper"
#通过命令提取nginx配置文件中的所有域名再排序去重，不要一个域名解析多个A记录，很频繁reload
domain=(`grep -w server /etc/nginx/*.conf|grep -Eio '([-a-z0-9\.]{1,61}[\.][-a-z0-9\.]{1,61})'|grep -v .conf|grep -v -E '([0-9]{1,3}[\.]){3}[0-9]{1,3}'|sort|uniq`)

#备份原hosts
if [ ! -f "/etc/hosts.bak" ];then 
	cp /etc/hosts /etc/hosts.bak
fi

#检测是否有host指令，如果没有就装一下
if [ "`command -v host`" == "" ]; then
    if [ ! -f "/etc/redhat-release" ]; then
        apt install -y dnsutils
    else 
	yum install -y bind-utils
    fi
fi

#删除可能遗留的缓存
rm -rf $WorkFile.changed
rm -rf $WorkFile.hosts

for rule in ${domain[@]}
do
	{
	ip=`host $rule|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'|sed -n '1p'`
	if [ "$ip" ];then 
		echo "$ip $rule">>$WorkFile.hosts
		if [ ! "`grep $ip /etc/hosts`" ];then touch $WorkFile.changed;fi
	else 
		#若某域名未解析到IP，就设置为保留IP 避免nginx启动失败
		echo "169.254.255.255 $rule">>$WorkFile.hosts
	fi
	}&
done
wait

if [ -f "$WorkFile.changed" ];then 
	`which cp|tail -1` -f /etc/hosts.bak /etc/hosts
	cat $WorkFile.hosts >>/etc/hosts
	rm -rf $WorkFile.changed
	systemctl reload nginx
fi
rm -rf $WorkFile.hosts

#若nginx当前服务未启动就尝试手动重启
if [ ! "`systemctl|grep nginx|grep -o running`" ];then 
	systemctl restart nginx
fi

#* * * * * root if [ "`systemctl |grep nginx|grep running`" == "" ];then systemctl restart nginx;fi 一句话的命令
