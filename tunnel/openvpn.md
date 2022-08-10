## 配置解释
```
#设备名称
dev ovpn-us
#设备类型，一般不变动
dev-type tun 
#协议类型，一般不变动
proto udp

#免密登录
auth-user-pass /etc/openvpn/passwd
auth-nocache
#不调整路由
route-nopull
#运行后执行的脚本，需要可执行权限，可以通过此脚本调整openvpn的路由
up '/etc/openvpn/openvpn.sh'
#参数优化
sndbuf 1048576 
rcvbuf 1048576 
txqueuelen 1000


#/etc/openvpn/openvpn.sh内容
#!/bin/bash
tun=ovpn-us
rule=104
#添加网卡默认路由表
ip route add default dev $tun table $rule
#删除之前的路由规则
ip rule del from 0.0.0.0/0 table $rule
#重新添加路由规则
ip=`ip a|grep $tun|grep inet|awk '{print $2}'|awk -F '/' '{print $1}'`
ip rule add from $ip table $rule

sed -i "s|SendIP.*|SendIP: $ip|g" /backend/us.yml
systemctl restart backend@us

#使用systemd来管理服务
vi /etc/systemd/system/ovpn-us.service

[Unit]
Description=OpenVPN service
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/openvpn --config /etc/openvpn/us.ovpn
Restart=always
[Install]
WantedBy=multi-user.target
```