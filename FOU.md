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
ip fou add port 5010 ipproto 4 #5000端口用来接收fou流量
ip link add tun0 type ipip local 172.17.0.111 remote 1.1.1.1 encap fou encap-sport 5000 encap-dport 5000 #添加一个网卡设备tun0
ip addr add 192.168.0.4 peer 192.168.0.3 dev tun0 #给tun0添加IP
ip link set tun0 up #启动网卡设备
```

执行完毕后一般隧道就打通了，服务端IP为192.168.0.1，客户端IP为192.168.0.2
