#!/bin/bash
#允许内核转发
echo 1 > /proc/sys/net/ipv4/ip_forward
#全局变量
forwardtemp=/tmp/forwardtemp
oldrule=/tmp/oldrule
#并设置定时任务，每分钟执行一次，为避免重复运行，可按下方示例添加(需先将该文件拷贝至/etc/目录下)，规则过多可适当降低运行频率
#echo "* * * * * root flock -xn /tmp/forward.lock -c 'bash /etc/forward.sh'" >> /etc/crontab
#与其他iptables的nat表的规则冲突，执行 	iptables -t nat -F POSTROUTING && iptables -t nat -F PREROUTING  可手动清除转发规则
#"本机IP 本机端口  远程域名(IP也可以) 远程端口",其中第二个参数若重复以前边的规则生效
#举例：  "192.168.1.1 1000  1.1.1.1 2000" 
#即本机的1000端口转发1.1.1.1:2000端口，其中本机IP可通过 ip a命令查看
ip=`ip a |grep -w inet|grep -v 127.0.0.1|sed -n '1p'|awk -F ' ' '{print $2}'|awk -F '/' '{print $1}'`
#上述命令来自动获取本机IP，因环境不同，请先手动执行一下是否获取正确，如果有多个IP，"sed -n '1p'"为指定输出第一个IP "sed -n '2p'"为第二个IP
#适用于多个VPS需要执行同样的转发规则进行负载均衡,直接拷贝脚本即可，不需要再更改本机IP
single_rule=(
	#注意前后的分号，一定不要忘记，可以增加注释不影响
	#"$ip 1000  example.com  888"
	#"192.168.1.101 1001  1.1.1.1 2000"
)
#端口段转发，方法与单端类似，注意的是前后端口段需一致
multi_rule=( 
	#注意前后的分号，一定不要忘记，可以增加注释不影响
	#"192.168.1.1 1000:2000 example1.com 1000:2000"
	#"192.168.1.1 3000:4000 example2.com 3000:4000"
)

if   [ "${single_rule[0]}" = "" -a  "${multi_rule[0]}" = "" ];then
    echo "当前无转发规则"
    exit 0
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
#单端口转发检测####################################
i=0
rule=${single_rule[${i}]}
while [ -n "$rule" ]
do
	#读取本地IP、读取本地端口、读取远程IP、读取远程端口
	local_ip=`echo $rule | awk -F ' ' '{print $1}'` 
	local_port=`echo $rule| awk -F ' ' '{print $2}'`
	remote_ip=`echo $rule | awk -F ' ' '{print $3}'`
	#判断第三个参数是否是IP,不是的话就解析成IP
	if [ "$(echo  $remote_ip |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" == "" ];then
		remote_ip=`host -t a  $remote_ip|grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"|head -1`
	fi
	#如果域名未解析出IP，就跳过此次循环
	if [ "$remote_ip" == "" ]; then let i++;rule=${single_rule[${i}]};continue; fi
	remote_port=`echo $rule | awk -F ' ' '{print $4}'`
	#如果不够四个参数，就跳过此次循环
	if [ "$remote_port" == "" ]; then let i++;rule=${single_rule[${i}]};continue; fi
	#对比iptables表里的规则，如果远程IP和端口变化了就进行标记
	iptables -t nat -nL >$oldrule
	if [ -z "`grep -w dpt:$local_port $oldrule|grep -w $remote_ip:$remote_port`" ];then is_changed=1; fi
	#写规则进临时文件
	echo "
iptables -t nat -A PREROUTING -p tcp -m tcp --dport $local_port -j DNAT --to-destination $remote_ip:$remote_port
iptables -t nat -A POSTROUTING -d $remote_ip -p tcp -m tcp --dport $remote_port -j SNAT --to-source $local_ip
" >>$forwardtemp
	#UDP转发规则，不需要可以注释掉
	echo "
iptables -t nat -A PREROUTING -p udp -m udp --dport $local_port -j DNAT --to-destination $remote_ip:$remote_port
iptables -t nat -A POSTROUTING -d $remote_ip -p udp -m udp --dport $remote_port -j SNAT --to-source $local_ip
" >>$forwardtemp
	let i++
	rule=${single_rule[${i}]}
done
#端口段转发检测####################################
i=0
rule=${multi_rule[${i}]}
while [ -n "$rule" ]
do
	#读取本地IP、读取本地端口、读取远程IP、读取远程端口
	local_ip=`echo $rule | awk -F ' ' '{print $1}'` 
	local_port=`echo $rule| awk -F ' ' '{print $2}'`
	local_start_port=`echo $local_port| awk -F ':' '{print $1}'`
	local_end_port=`echo $local_port| awk -F ':' '{print $2}'`
    remote_ip=`echo $rule | awk -F ' ' '{print $3}'`
	#判断第三个参数是否是IP,不是的话就解析一下
	if [ "$(echo  $remote_ip |grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}')" == "" ];then
		remote_ip=`host -t a  $remote_ip|grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"|head -1`
	fi
	#如果域名未解析出IP，就跳过此次循环
	if [ "$remote_ip" == "" ]; then let i++;rule=${single_rule[${i}]};continue; fi
	remote_port=`echo $rule | awk -F ' ' '{print $4}'`
	#如果不够四个参数，就跳过此次循环
	if [ "$remote_port" == "" ]; then let i++;rule=${single_rule[${i}]};continue; fi
	remote_start_port=`echo $remote_port| awk -F ':' '{print $1}'`
	remote_end_port=`echo $remote_port| awk -F ':' '{print $2}'`
	#对比iptables表里的规则，如果远程IP和端口变化了就进行标记
	iptables -t nat -nL >$oldrule
	if [ -z "`grep -w dpts:$local_port $oldrule|grep -w $remote_ip:$remote_start_port-$remote_end_port`" ];then is_changed=1; fi
	#写规则进临时文件
	echo "
iptables -t nat -A PREROUTING -p tcp -m tcp --dport $local_port -j DNAT --to-destination $remote_ip:$remote_start_port-$remote_end_port
iptables -t nat -A POSTROUTING -d $remote_ip -p tcp -m tcp --dport $remote_port -j SNAT --to-source $local_ip
" >>$forwardtemp
	#UDP转发规则，不需要可以注释掉
	echo "
iptables -t nat -A PREROUTING -p udp -m udp --dport $local_port -j DNAT --to-destination $remote_ip:$remote_start_port-$remote_end_port
iptables -t nat -A POSTROUTING -d $remote_ip -p udp -m udp --dport $remote_port -j SNAT --to-source $local_ip
" >>$forwardtemp
	let i++
	rule=${multi_rule[${i}]}
done

#如果前方标记了变化，则执行临时文件中的iptables规则
if [ "$is_changed" == 1 ];then 
	iptables -t nat -F POSTROUTING && iptables -t nat -F PREROUTING
	bash $forwardtemp && rm -f $forwardtemp
	#如果有docker，需要再重启下docker服务
	#systemctl restart docker
	echo "IP有变化，已刷新iptables规则"
else 
	echo "IP无变动"
	rm -f $forwardtemp
fi
