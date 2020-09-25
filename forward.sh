#!/bin/bash
#允许内核转发
echo 1 > /proc/sys/net/ipv4/ip_forward
#缓存目录，默认是共享内存
workdir="/dev/shm"

#并设置定时任务，每分钟执行一次，为避免重复运行，可按下方示例添加(需先将该文件拷贝至/etc/目录下)，规则过多可适当降低运行频率
#echo "* * * * * root flock -xn /dev/shm/forward.lock -c 'bash /etc/forward.sh'" >> /etc/crontab
#与其他iptables的nat表的规则有冲突，执行 bash forward.sh clean 清除d当前转发规则
#"本机IP 本机端口  远程域名(IP也可以) 远程端口",若本地端口填写重复，旧添加的生效
#举例：  "192.168.1.1 1000  1.1.1.1 2000" 
#即本机的1000端口转发1.1.1.1:2000端口，其中本机IP可通过 ip a命令查看
ip=`ip a |grep -w inet|grep -v 127.0.0.1|sed -n '1p'|awk -F ' ' '{print $2}'|awk -F '/' '{print $1}'`
#上述命令来自动获取本机IP，因环境不同，请先手动执行一下是否获取正确，如果有多个IP，"sed -n '1p'"为指定输出第一个IP "sed -n '2p'"为第二个IP
#适用于多个VPS需要执行同样的转发规则进行负载均衡,直接拷贝脚本即可，不需要再更改本机IP

#单端口转发规则
single_rule=(
	#注意前后的分号，一定不要忘记，可以增加注释不影响
	#"$ip 1000  example.com  888"
	#"192.168.1.101 1001  1.1.1.1 2000"
)
#端口段转发规则，方法与单端类似，注意的是前后端口段需保持一致
multi_rule=( 
	#"192.168.1.1 1000:2000 example1.com 1000:2000"
	#"192.168.1.1 3000:4000 example2.com 3000:4000"
)

if [ "$1" = "clean" ];then 
	iptables -t nat -F POSTROUTING
	iptables -t nat -F PREROUTING
	exit 0
fi

if [ "${single_rule[*]}" = "" -a  "${multi_rule[*]}" == "" ];then
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

#删除可能遗留的缓存
rm -rf $workdir/forward.rule
rm -rf $workdir/forward.tmp
rm -rf $workdir/forward.changed

#将当前iptables规则表导出
echo "`iptables -t nat -nL`">$workdir/forward.rule

#单端口转发检测
for i in "${!single_rule[@]}";
do
	{
	rule="${single_rule[$i]}"
	#读取本地IP、读取本地端口、读取远程IP、读取远程端口
	local_ip=`echo $rule|awk '{print $1}'` 
	local_port=`echo $rule|awk '{print $2}'`
	remote_ip=`echo $rule|awk '{print $3}'`
	remote_port=`echo $rule|awk '{print $4}'`
	#判断第三个参数是否是IP,不是的话就解析成IP
	if [ ! "`echo $remote_ip|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`" ];then
		remote_ip=`host $remote_ip|grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"|head -1`
	fi
	#如果域名未解析出IP，就跳过此次循环
	if [ "$remote_ip" != "" -a "$remote_port" != "" ];then
		#判断iptables是否有这条规则，如果有就创建一个$workdir/forward.changed进行标记
		if [ ! "`grep -w dpt:$local_port $workdir/forward.rule|grep -w $remote_ip:$remote_port`" ];then touch $workdir/forward.changed;fi
		#写规则进临时文件
		echo "
iptables -t nat -A PREROUTING -p tcp --dport $local_port -j DNAT --to-destination $remote_ip:$remote_port
iptables -t nat -A POSTROUTING -d $remote_ip -p tcp --dport $remote_port -j SNAT --to-source $local_ip">>$workdir/forward.tmp
		#UDP转发规则，不需要可以注释掉
		echo "
iptables -t nat -A PREROUTING -p udp --dport $local_port -j DNAT --to-destination $remote_ip:$remote_port
iptables -t nat -A POSTROUTING -d $remote_ip -p udp --dport $remote_port -j SNAT --to-source $local_ip">>$workdir/forward.tmp
	fi
	}&
done
#端口段转发检测
for j in ${!multi_rule[@]}
do
	{
	rule=${multi_rule[$j]}
	#读取本地IP、读取本地端口、读取远程IP、读取远程端口
	local_ip=`echo $rule|awk '{print $1}'` 
	local_port=`echo $rule|awk '{print $2}'`
	local_start_port=`echo $local_port|awk -F ':' '{print $1}'`
	local_end_port=`echo $local_port|awk -F ':' '{print $2}'`
	remote_ip=`echo $rule|awk '{print $3}'`
	remote_port=`echo $rule|awk '{print $4}'`
	#判断第三个参数是否是IP,不是的话就解析一下
	if [ "$`echo $remote_ip|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`" ];then
		remote_ip=`host $remote_ip|grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"|head -1`
	fi
	#如果域名未解析出IP，就跳过此次循环
	if [ "$remote_ip" != "" -a "$remote_port" != "" ];then
		remote_start_port=`echo $remote_port| awk -F ':' '{print $1}'`
		remote_end_port=`echo $remote_port| awk -F ':' '{print $2}'`
		if [ ! "`grep -w dpts:$local_port $workdir/iptables.rule|grep -w $remote_ip:$remote_start_port-$remote_end_port`" ];then touch $workdir/forward.changed;fi
		#TCP转发规则写入
		echo "
iptables -t nat -A PREROUTING -p tcp --dport $local_port -j DNAT --to-destination $remote_ip:$remote_start_port-$remote_end_port
iptables -t nat -A POSTROUTING -d $remote_ip -p tcp --dport $remote_port -j SNAT --to-source $local_ip">>$workdir/forward.tmp
		#UDP转发规则写入
		echo "
iptables -t nat -A PREROUTING -p udp --dport $local_port -j DNAT --to-destination $remote_ip:$remote_start_port-$remote_end_port
iptables -t nat -A POSTROUTING -d $remote_ip -p udp --dport $remote_port -j SNAT --to-source $local_ip">>$workdir/forward.tmp
	fi
	}&
done

#等待判断完毕
wait

#如果前方标记了变化，则执行临时文件中的iptables规则
if [ -f "$workdir/forward.changed" ];then 
	iptables -t nat -F POSTROUTING
	iptables -t nat -F PREROUTING
	bash $workdir/forward.tmp
	#如果有docker，可能还需要再重启下docker服务
	#systemctl restart docker
	echo "IP有变化，已刷新iptables规则"
else 
	echo "IP无变动"
fi

#删除缓存
rm -rf $workdir/forward.rule
rm -rf $workdir/forward.tmp
rm -rf $workdir/forward.changed


