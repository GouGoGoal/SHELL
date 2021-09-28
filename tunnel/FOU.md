# Foo over UDP 
Linux内核(3.18+)带的UDP隧道<br>
将IPIP封装进FOU隧道里，即可用UDP打通内网，内核级的VPN，开销非常小，IPIP隧道没有加密，一般常用于TCP有限速的环境，或低消耗打通内网<br>
一个服务端只对应一个服务端<br>
预设环境<br>
服务端公网IP：eth0 1.1.1.1<br>
客户端为NAT环境或动态IP，eth0 172.17.0.111<br>

```
## 服务端
modprobe fou
ip fou add port 5000 ipproto 4 #5000端口用来接收fou流量

iptables -t nat -A INPUT -i eth0 -p udp --dport 5000  -j SNAT --to-source 192.168.0.255:5000 #入5000端口的UDP流量改写源地址，当客户端无公网端口或动态IP时用
ip link add tun0 type ipip local 1.1.1.1 remote 192.168.0.255 encap fou encap-sport 5000 encap-dport 5000 #添加一个设备tun0，若客户端不是NAT，就写公网IP
ip addr add 192.168.0.1 peer 192.168.0.2 dev tun0 #给tun0添加IP
ip link set tun0 up #启动设备
#iptables -A FORWARD -i tun-0 -j ACCEPT  #若想客户端走服务端路由
#iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE  #需要额外执行这两行

#客户端
modprobe fou
ip fou add port 5000 ipproto 4 #5000端口用来接收fou流量
ip link add tun0 type ipip local 172.17.0.111 remote 1.1.1.1 encap fou encap-sport 5000 encap-dport 5000 #添加一个网卡设备tun0
ip addr add 192.168.0.2 peer 192.168.0.1 dev tun0 #给tun0添加IP
ip link set tun0 up #启动网卡设备
nohup ping 192.168.0.1 & #持续ping服务端来保活
#ip rule add from 192.168.0.2 table 100 #客户端若想使用其路由
#ip route add default dev tun0 table 100 #添加这个路由表并设置默认路由
```
若一方为动态IP或无公网IP，需要在服务端运行此脚本，脚本 IP 端口视情况更改
```
#!/bin/bash
while :
do
	if [ ! "`ping -W 1 -c 2 192.168.0.2|grep time=`" ];then 
		conntrack -D -p udp --dport 5000
	fi
	sleep 5s
done

```


