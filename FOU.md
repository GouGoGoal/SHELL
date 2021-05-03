# Foo over UDP 
Linux内核(3.18+)带的UDP隧道<br>
将IPIP封装进FOU隧道里，即可用UDP打通内网，内核级的VPN，开销非常小，IPIP隧道没有加密，一般常用于TCP有限速的环境，或低消耗打通内网<br>
一个服务端只对应一个服务端<br>
预设环境<br>
服务端公网IP：eth0 1.1.1.1<br>
客户端为NAT环境或动态IP，eth0 172.17.0.111<br>

## 先加载fou模块，需要内核版本≥3.18
```modprobe fou```
```
## 服务端
ip fou add port 5000 ipproto 4 #5000端口用来接收fou流量
iptables -t nat -A INPUT -i eth0 -p udp --dport 5000  -j SNAT --to-source 192.168.0.255:5000 #入5000端口的UDP流量改写源地址，当客户端无公网端口或动态IP时用
ip link add tun0 type ipip local 1.1.1.1 remote 192.168.0.255 encap fou encap-sport 5000 encap-dport 5000 #添加一个设备tun0，若客户端不是NAT，就写公网IP
ip addr add 192.168.0.1 peer 192.168.0.2 dev tun0 #给tun0添加IP
ip link set tun0 up #启动设备
 
#客户端
ip fou add port 5000 ipproto 4 #5000端口用来接收fou流量
ip link add tun0 type ipip local 172.17.0.111 remote 1.1.1.1 encap fou encap-sport 5000 encap-dport 5000 #添加一个网卡设备tun0
ip addr add 192.168.0.2 peer 192.168.0.1 dev tun0 #给tun0添加IP
ip link set tun0 up #启动网卡设备
```
执行完毕后一般隧道就打通了，服务端IP为192.168.0.1，客户端IP为192.168.0.2<br>
特别注意，当客户端IP变化时，隧道会GG，我们可以通过简单的定时任务来保活(此法适合动态IP向静态IP发起连接，反过来经常容易GG)<br>
```
保持两端的时间一致◆重要
动态IP的一端(客户端)添加一个定时任务，每个整分钟ping五下服务端
* * * * * root ping -c15 -i 0.2 -W1 192.168.0.1 
静态IP的一端(服务端)添加一个定时任务，即若ping不通了(多半是IP变了)，就删除这个连接，需提前安装 apt install conntrack
* * * * * root if [ ! "`ping -c2 -i 0.5 -W1 192.168.0.2|grep '^rtt'|awk -F '/' '{print $5}'`" ];then  conntrack -D -p udp --dport 5000;fi
原理即每个整分钟，客户端每隔0.2秒向服务端ping15个包用来建立连接
服务端每隔0.5秒向客户端ping2个包，若不通(没有延迟数字)，就删除这个udp连接，此时客户端还在尝试ping，即可重新建立连接
```
另辟蹊径，让客户端(动态IP)一方定时向服务端(静态IP)SSH写入当前公网IP，若发生了变化，就删除这个虚拟网卡然后与新的客户端IP重新建立<br>
此方法需要两边都有公网IP或端口，动态IP方做好免密
```
动态IP的一端(客户端)添加一个定时任务，每分钟获取当前本机IP并scp到静态IP的一端(服务端)
* * * * * root curl -s ip.sb > /tmp/MyIP;scp /tmp/MyIP root@1.1.1.1:/tmp/FOU-Client-IP

静态IP的一端(服务端)添加一个定时任务，获取客户端传来的IP进行对比，如果变化了删除网卡重新建立
* * * * * root bash /etc/FOU.sh
脚本内容如下

#!/bin/bash
sleep 2s
FOUClientIP=`cat /tmp/FOUClientIP`
if [ ! `ip link show|grep -o $FOUClientIP` ];then 
	ip fou del tun-hinet
	ip link add tun-hinet type ipip local 1.1.1.1 remote $FOUClientIP encap fou encap-sport auto encap-dport 5010
	ip addr add 192.168.0.1 peer 192.168.0.2 dev tun-hinet
	ip link set tun-hinet up
fi
```

## WireGuard
```
echo "deb http://deb.debian.org/debian buster-backports main" >>/etc/apt/sources.list
apt -y update 
apt -y upgrade
#手动重启
apt -t buster-backports install wireguard wireguard-tools wireguard-dkms linux-headers-$(uname -r)
modprobe wireguard

#添加源进源出路由,192.168.0.2是本机IP，192.168.0.1是网关，网卡eth0
ip rule add from 1192.168.0.2 table 100
ip route add default via 192.168.0.1 dev eth0 table 100


#wgcf里手动添加一行用以保活
echo "PersistentKeepalive = 10" >>/etc/wireguard/wgcf.conf

ip link add wgcf type wireguard
wg setconf wgcf /etc/wireguard/wgcf.conf
ip -4 address add 172.16.0.2/32 dev wgcf
#ip -6 address add fd01:5ca1:ab1e:82f1:bfa8:d22b:435b:f4a3/128 dev wgcf  #添加IPV6时需要
ip link set mtu 1280 up dev wgcf

#将默认路由改为wgcf
ip route change default dev wgcf 

#添加IPV6默认路由
ip -6 route add default dev wgcf
```



