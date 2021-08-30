## 安装新版内核，含wireguard模块
```
#升级最新版内核
echo "deb `cat /etc/apt/sources.list|grep deb-src|awk '{print $2,$3}'`-backports main" >> /etc/apt/sources.list
apt update
apt -t `cat /etc/apt/sources.list|grep deb-src|awk '{print $3}'`-backports install linux-image-amd64 linux-headers-amd64 -y 
update-grub
modprobe wireguard
```
## 注册 WARP
```
https://github.com/ViRb3/wgcf/releases/download/v2.2.5/wgcf_2.2.5_linux_amd64
chmod +x wgcf_2.2.5_linux_amd64
./wgcf_2.2.5_linux_amd64 register

./wgcf_2.2.5_linux_amd64 generate
mv wgcf-profile.conf /etc/wireguard/wgcf.conf


#保活
echo "PersistentKeepalive = 10" >>/etc/wireguard/wgcf.conf
#注释多余行
sed -i 's/Address/#Address/' /etc/wireguard/wgcf.conf
sed -i 's/DNS/#DNS/' /etc/wireguard/wgcf.conf
sed -i 's/MTU/#MTU/' /etc/wireguard/wgcf.conf
```
## 路由配置
```
#WARP地址走100路由表
ip rule add to 162.159.192.1 table 100
#访问本机IP的走100路由表，192.168.0.2是本机IP，192.168.0.1是网关IP，eth0是网卡名称
ip rule add from 192.168.0.2 table 100
ip route add default via 192.168.0.1 dev eth0 table 100

ip link add wgcf type wireguard
wg setconf wgcf /etc/wireguard/wgcf.conf
ip -4 address add 172.16.0.2/32 dev wgcf
#ip -6 address add fd01:5ca1:ab1e:82f1:bfa8:d22b:435b:f4a3/128 dev wgcf  #添加IPV6时需要
ip link set mtu 1280 up dev wgcf
#添加WGCF的路由表
ip rule add from 172.16.0.2 table 101
ip route add default dev wgcf table 101

#将默认路由改为wgcf
ip route change default dev wgcf
#添加IPV6默认路由
#ip -6 route add default dev wgcf


#部分服务走WARP
wget -P /etc/ https://github.com/GouGoGoal/SHELL/raw/master/tunnel/WARP/cloudflare.ip
wget -P /etc/ https://github.com/GouGoGoal/SHELL/raw/master/tunnel/WARP/facebook.ip
wget -P /etc/ https://github.com/GouGoGoal/SHELL/raw/master/tunnel/WARP/netflix.ip
wget -P /etc/ https://github.com/GouGoGoal/SHELL/raw/master/tunnel/WARP/twitter.ip
for ip in `cat /etc/cloudflare.ip`;do ip rule add to $ip table 100;done
for ip in `cat /etc/netflix.ip`;do ip rule add to $ip table 101;done
for ip in `cat /etc/twitter.ip`;do ip rule add to $ip table 101;done
for ip in `cat /etc/facebook.ip`;do ip rule add to $ip table 101;done
```



