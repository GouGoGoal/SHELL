#!/bin/bash
#旨在解决nginx转发动态域名时不会自动更新，以及缓解域名过多时出现的解析失败的现象
#若使用此脚本不要在nginx里使用resolver参数，并按下方命令添加计划任务
#echo "* * * * * root flock -xn /dev/shm/hosts.lock -c 'bash /etc/nginx/nginx_helper.sh'">>/etc/crontab
#指定DNS
DNS=223.5.5.5
#缓存文件
WorkFile="/dev/shm/ng_healper"
#通过命令提取nginx配置文件中的所有域名再排序去重，建议不要一个域名解析多个A记录，很频繁reload
domain=(`grep -w server /etc/nginx/*.conf|grep -v '#server'|grep -Eio '([-a-z0-9\.]{1,61}[\.][-a-z0-9\.]{1,61})'|grep -v .conf|grep -v -E '([0-9]{1,3}[\.]){3}[0-9]{1,3}'|sort|uniq`)

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
#依次解析成IP，若/etc/hosts不存在这条解析，则标记为有变化
for rule in ${domain[@]}
do
	{
	ip=`host -T -W 1 $rule $DNS|grep -w address|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'|sed -n '1p'`
	if [ "$ip" ];then 
		if [ ! "`cat /etc/hosts|grep -w "$ip $rule"`" ];then 
			touch $WorkFile.changed
			sed -i "/$rule$/d" /etc/hosts
			echo "$ip $rule">>/etc/hosts
		fi
	else 
		#若某域名未解析到IP，就设置为169.254.255.255 避免nginx启动失败
		sed -i "/$rule$/d" /etc/hosts
		echo "169.254.255.255 $rule">>/etc/hosts
	fi
	}&
done
#等待处理完毕
wait
#如果有变化就重载nginx
if [ -f "$WorkFile.changed" ];then 
	rm -rf $WorkFile.changed
	systemctl reload nginx
fi
#若nginx当前服务未启动就尝试重启服务
if [ ! "`ps -ef |grep nginx|grep -v grep|grep -v ng_helper`" ];then 
	systemctl restart nginx
fi
