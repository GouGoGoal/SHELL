#!/bin/bash
#允许内核转发
echo 1 > /proc/sys/net/ipv4/ip_forward
#缓存文件前缀，如果设置了多个转发脚本，请保持此处不同
WorkFile='/dev/shm/forward'
#运行过程请不要CTRL+C 取消，也不要同时运行多次此脚本(先取消定时任务再手动执行)
#执行 bash forward.sh clean 可清除规则，与docker不冲突(端口发生冲突时除外)
if [ "$1" = "clean" ];then sed -i "s|-A|-D|" $WorkFile.last_rules;bash $WorkFile.last_rules;rm -rf $WorkFile.last_rules;echo "规则已清除";exit;fi
#设置定时任务，每分钟执行一次，命令示例如下
#echo "* * * * * root flock -xn /dev/shm/forward.lock -c 'bash /etc/forward.sh'" >> /etc/crontab
#ip=`ip a|grep -w inet|grep -v 127.0.0.1|awk '{print $2}'|awk -F '/' '{print $1}'|sed -n '1p'` #如果不用此参数请不要取消注释，会影响下方代码判断
#上述命令来自动获取本机IP，因环境不同，请先手动执行一下是否获取正确，如果有多个IP，最后可以改为sed -n '2p'|'3p'，适用于本地为动态IP
#单端口转发规则
Single_Rule=(
	#本机地址 本机端口 远程地址 远程端口
	#"$ip 1000  example.com  888"
	#"192.168.1.101 1001  1.1.1.1 2000"
)
#端口段转发规则，和单端口顺序一致，端口段需保持一致
Multi_Rule=( 
	#"$ip 1000:2000 example1.com 1000:2000"
	#"192.168.1.1 3000:4000 example2.com 3000:4000"
)

#删除可能遗留的缓存
rm -rf $WorkFile.iptables
rm -rf $WorkFile.hosts
rm -rf $WorkFile.is_changed

if [ ! "${Single_Rule[*]}"  -a ! "${Multi_Rule[*]}" ];then echo "当前无转发规则";exit;fi

rm -rf $WorkFile.domain
#收集域名进$WorkFile.domain
for list in "${Single_Rule[@]}";
do
	list=($list)
	echo ${list[2]}>>$WorkFile.domain
done
for list in "${Multi_Rule[@]}";
do
	rule=($list)
	echo ${list[2]}>>$WorkFile.domain
done
Domain=`sort $WorkFile.domain|uniq|grep -v -E '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`
rm -rf $WorkFile.domain

#检查host指令
if [ ! "`command -v host`" ];then
    if [ ! -f "/etc/redhat-release" ];then
        apt install -y host
    else 
		yum install -y bind-utils
    fi
	if [ "$?"!= 0 ];then 
		echo "host命令安装失败，请自行解决后重新运行该脚本"
		exit
	fi
fi

#将解析的IP与对应域名输出
for domain in `echo "$Domain"`
do
	{
	domain_ip=`host -4 -t A -W 1 $domain|grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"|head -1`
	if [ "$domain_ip" ];then echo "$domain $domain_ip">>$WorkFile.hosts;fi
	}&
done
wait

#将当前iptables规则表导出
echo "`iptables -t nat -nL|grep NAT`">$WorkFile.iptables

#若本地IP变化，则刷新规则
if [ "$ip" ];then
	if [ ! "`grep -o $ip $WorkFile.iptables`" ];then touch $WorkFile.is_changed;fi
fi


#单端口转发检测
for rule in "${Single_Rule[@]}";
do
	{
	rule=($rule)
	#若此条规则多于四个参数，就略过此规则
	if [ ${#rule[*]} == 4 ];then
		#拆分本地IP、本地端口、远程IP、远程端口
		Local_IP=${rule[0]} 
		Local_Port=${rule[1]} 
		Remote_IP=${rule[2]} 
		Remote_Port=${rule[3]}
		#判断第三个参数是否是IP,是的话跳过此次循环
		if [ ! "`echo $Remote_IP|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`" ];then 
			Remote_IP=`grep -w $Remote_IP $WorkFile.hosts|awk '{print $2}'`
		fi
		#如果域名解析出IP，就暂存规则
		if [ "$Remote_IP" ];then
			#判断iptables是否有这条规则，如果有就创建一个$WorkFile.changed文件进行标记
			if [ ! "`grep DNAT $WorkFile.iptables|grep dpt:$Local_Port|grep to:$Remote_IP:$Remote_Port`" ];then
				touch $WorkFile.is_changed
			elif [ ! "`grep SNAT $WorkFile.iptables|grep $Remote_IP|grep dpt:$Remote_Port`" ];then
				touch $WorkFile.is_changed
			fi
			#写规则进临时文件，两条TCP，两条UDP，可以根据实际使用删除
			echo "
iptables -t nat -A PREROUTING -p tcp --dport $Local_Port -j DNAT --to-destination $Remote_IP:$Remote_Port
iptables -t nat -A POSTROUTING -d $Remote_IP -p tcp --dport $Remote_Port -j SNAT --to-source $Local_IP
iptables -t nat -A PREROUTING -p udp --dport $Local_Port -j DNAT --to-destination $Remote_IP:$Remote_Port
iptables -t nat -A POSTROUTING -d $Remote_IP -p udp --dport $Remote_Port -j SNAT --to-source $Local_IP
">>$WorkFile.rules
		fi
	fi
	}&
done
wait #等待判断完毕

#端口段转发检测
for rule in "${Multi_Rule[@]}";
do
	{
	rule=($rule)
	#若此条规则有效时(四个参数)才进行解析
	if [ ${#rule[*]} == 4 ];then
		#拆分本地IP、本地端口、远程IP、远程端口
		Local_IP=${rule[0]} 
		Local_Port=${rule[1]}
		Local_Start_Port=`echo $Local_Port|awk -F ':' '{print $1}'`
		Local_End_Port=`echo $Local_Port|awk -F ':' '{print $2}'`
		Remote_IP=${rule[2]} 
		Remote_Port=${rule[3]}
		Remote_Start_Port=`echo $Remote_Port|awk -F ':' '{print $1}'`
		Remote_End_Port=`echo $Remote_Port|awk -F ':' '{print $2}'`
		#判断第三个参数是否是IP,是的话跳过此次循环
		if [ ! "`echo $Remote_IP|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`" ];then 
			Remote_IP=`grep -w $Remote_IP $WorkFile.hosts|awk '{print $2}'`
		fi
		#如果域名解析出IP，就暂存规则
		if [ "$Remote_IP" ];then
			#判断iptables是否有这条规则，如果有就创建一个$WorkFile.changed进行标记
			if [ ! "`grep DNAT $WorkFile.iptables|grep dpts:$Local_Port|grep $Remote_IP:$Remote_Start_Port-$Remote_End_Port`" ];then 
				touch $WorkFile.is_changed
			elif [ ! "`grep SNAT $WorkFile.iptables|grep $Remote_IP|grep  dpts:$Remote_Start_Port:$Remote_End_Port`" ];then
				touch $WorkFile.is_changed
			fi
			#写规则进临时文件，两条TCP，两条UDP，可以根据实际使用删除
			echo "
iptables -t nat -A PREROUTING -p tcp --dport $Local_Port -j DNAT --to-destination $Remote_IP:$Remote_Start_Port-$Remote_End_Port
iptables -t nat -A POSTROUTING -d $Remote_IP -p tcp --dport $Remote_Port -j SNAT --to-source $Local_IP
iptables -t nat -A PREROUTING -p udp --dport $Local_Port -j DNAT --to-destination $Remote_IP:$Remote_Start_Port-$Remote_End_Port
iptables -t nat -A POSTROUTING -d $Remote_IP -p udp --dport $Remote_Port -j SNAT --to-source $Local_IP
">>$WorkFile.rules
		fi
	fi
	}&
done
wait #等待判断完毕

#如果前方标记了变化，则执行临时文件中的iptables规则
if [ -f "$WorkFile.is_changed" ];then 
	echo "IP有变化，正在刷新iptables规则"
	if [ -f "$WorkFile.last_rules" ];then
		sed -i "s|-A|-D|" $WorkFile.last_rules
		bash $WorkFile.last_rules
	fi
	bash $WorkFile.rules
	echo "刷新完毕"
	mv $WorkFile.rules $WorkFile.last_rules
	rm -rf $WorkFile.is_changed
else rm -rf $WorkFile.rules
fi
rm -rf $WorkFile.iptables
rm -rf $WorkFile.hosts
