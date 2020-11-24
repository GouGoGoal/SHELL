## 聊聊路由的那些事儿

```
#访问1.1.1.1通过109.166.36.129网关
ip route add 1.1.1.1 via 109.166.36.129


#原路返回设置
ip route add default via 192.168.0.1 table 100
ip rule add from 192.168.0.2 table 100

ip route add default via 192.168.1.1 table 101
ip rule add from 192.168.1.2 table 101
ip rule add from 192.168.1.3 table 101
#多个IP时，数字要变化
#多个IP网关一样时，可以省略一条命令


#多网卡均衡
ip route replace default equalize nexthop dev ppp0 weight 1 nexthop dev ppp1 weight 1
```




