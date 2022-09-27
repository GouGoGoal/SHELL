### iptables 基本参数解释
-P	设置默认策略<br>
-F	清空规则链<br>
-D	删除某个规则<br>
-L	查看规则链<br>
-n	输出全部显示为数字<br>
-A	在规则链末尾添加规则，优先级最低<br>
-I	在规则链头部添加规则，优先级高<br>
-s	匹配来源地址<br>
! -s	上条规则取反<br>
-d	匹配目标地址<br>
-i	匹配从这块网卡流入的数据<br>
-o	匹配从这块网卡流出的数据<br>
-p	匹配协议TCP、UDP、ICMP<br>
--dport	匹配目标端口号<br>
--sport	匹配来源端口号<br>
```
示例：
iptables -P INPUT DROP #更改默认INPUT策略为DROP，即丢弃所有入网连接
iptables -t nat -nL #查看nat表中的所有规则
iptables -t nat -F #清空nat表中的所有规则
iptables -I INPUT -s 1.1.1.1 -j ACCEPT #允许1.1.1.1连接本机
iptables -D INPUT -s 1.1.1.1 -j ACCEPT #清除上一条规则
iptables -I INPUT ! -s 1.1.1.1 -j DROP #不允许1.1.1.1以外的IP连接本机
iptables -I OUTPUT -d 1.1.1.1 --dport 80 -j DROP #拒绝本机连接1.1.1.1:80
iptables -I INPUT  -s 1.1.1.1 --dport 80 -j DROP #拒绝1.1.1.1连接本机80端口

iptables -I OUTPUT -p udp  --dport 443 -j DROP #屏蔽443UDP，即禁用quic
```
#限速命令
```
#80 443端口限速512k，每个访问的IP都限制
iptables -A INPUT -i ens3 -p tcp -m multiport --dport 80,443 -m hashlimit --hashlimit-above 512kb/s --hashlimit-mode srcip --hashlimit-name in -j DROP			

#对本机去往1.1.1.1:80的下行限速
iptables -A OUTPUT -d 1.1.1.1 -p tcp --dport 80 -m hashlimit --hashlimit-above 512kb/s --hashlimit-mode dstip --hashlimit-name out -j DROP

#访问本机80端口上行限速
iptables -A INPUT -p tcp --dport 80 -m hashlimit --hashlimit-above 512kb/s --hashlimit-mode srcip --hashlimit-name in -j DROP	




#将监听在127.0.0.1:1000的服务暴露至某个IP上，需要更改内核参数 net.ipv4.conf.ens3.route_localnet=1
iptables -t nat -A PREROUTING -p tcp --dport 1000 -j DNAT --to-destination 127.0.0.1:1000
```

```
#获取当前主网卡
eth=`ip route |grep default|grep -oE "dev.*"|awk '{print $2}'`

#nat表
INPUT：处理入站数据包
OUTPUT：处理出站数据包
FORWARD：处理转发数据包
POSTROUTING链：在进行路由选择后处理数据包（对数据链进行源地址修改转换）
PREROUTING链：在进行路由选择前处理数据包（做目标地址转换）
```
