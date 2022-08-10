#!/bin/bash
#允许内核转发
echo 1 > /proc/sys/net/ipv4/ip_forward
BaseName=$(basename $BASH_SOURCE)
#缓存文件前缀，如果设置了多个转发脚本，请保持此处不同
WorkFile="/dev/shm/$BaseName"
#运行过程请不要CTRL+C 取消，也不要同时运行多次此脚本(先取消定时任务再手动执行)
#执行 bash forward.sh clean 可清除全部规则
#执行 bash forward.sh clean 12345  可清除12345对应端口的规则
if [ "$1" = "clean" ];then
       if [ "$2" ];then 
		sed "s|-A|-D|" $WorkFile.rule.$2|bash
		rm $WorkFile.rule.$2
		echo "$2 端口规则已清除"
	else
		sed "s|-A|-D|" $WorkFile.rule.*|bash
		rm $WorkFile.*
		echo "全部规则已清除"
	fi
	exit
fi


if [ ! "`ls -lh /etc|grep $BaseName`" ];then
	mv $0 /etc
	echo "已将该脚本移动至/etc/$BaseName"
	echo "若需要转发动态域名，请再执行下方命令"
	echo "echo \"* * * * * root flock -xn /dev/shm/$BaseName.lock -c 'bash /etc/$BaseName'\" >> /etc/crontab"
fi

ip=`ip a|grep -w inet|awk '{print $2}'|awk -F '/' '{print $1}'|sed -n '2p'`
#上述命令来自动获取本机IP，因环境不同，请先手动执行一下是否获取正确，如果有多个IP，最后可以改为sed -n '3p'|'4p'；适用于本地为动态IP

#单端口转发规则
Single_Rule=(
	#本机地址 本机端口 远程地址 远程端口
	#"$ip 1000  example.com  888"
	#"192.168.1.101 1001  1.1.1.1 2000"	
)

#删除可能遗留的缓存
rm -rf $WorkFile.iptables
rm -rf $WorkFile.hosts

if [ ! "${Single_Rule[*]}" ];then echo "当前无转发规则";exit;fi

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
		apt update
        apt install -y host
    else 
		yum install -y bind-utils
    fi
	if [ "$?" != 0 ];then 
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
	sleep 0.1s #如果执行时CPU飙升，请酌情更改
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
			#判断iptables是否有这条规则
			if [ ! "`grep DNAT $WorkFile.iptables|grep dpt:$Local_Port|grep to:$Remote_IP:$Remote_Port`" -o ! "`grep SNAT $WorkFile.iptables|grep $Remote_IP|grep dpt:$Remote_Port`" ];then
				#就将对应本地端口的规则删除，然后重新写入并执行
				if [ -f "$WorkFile.rule.$Local_Port" ];then 
					sed -i "s|-A|-D|" $WorkFile.rule.$Local_Port
					bash $WorkFile.rule.$Local_Port >/dev/null 2>&1
				fi
				#写规则进临时文件，两条TCP，两条UDP，可以根据实际使用删除
				echo "
iptables -t nat -A PREROUTING -p tcp --dport $Local_Port -j DNAT --to-destination $Remote_IP:$Remote_Port
iptables -t nat -A POSTROUTING -d $Remote_IP -p tcp --dport $Remote_Port -j SNAT --to-source $Local_IP
iptables -t nat -A PREROUTING -p udp --dport $Local_Port -j DNAT --to-destination $Remote_IP:$Remote_Port
iptables -t nat -A POSTROUTING -d $Remote_IP -p udp --dport $Remote_Port -j SNAT --to-source $Local_IP
">$WorkFile.rule.$Local_Port
				#执行新的规则，并输出提示
				bash $WorkFile.rule.$Local_Port >/dev/null 2>&1
				echo "$Local_Port 端口规则已更新"
			fi

		fi
	fi
	}&
done
wait #等待判断完毕

#删除缓存
rm -rf $WorkFile.iptables
rm -rf $WorkFile.hosts
