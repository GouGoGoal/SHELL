### Linux 网络重装系统脚本
理论支持 CentOS6及以下，Debian 和Ubuntu，可能会造成失联，此脚本已魔改，安装完毕后不支持SSH密码登录，请不要使用<br>
```
bash <(curl -k https://raw.githubusercontent.com/GouGoGoal/SHELL/master/InstallNET.sh) -d 10 -v 64 -a [-p PassWord] [-i eth0] [--mirror  ...]
```
-d 10 为Debian 10<br>
-v 为64位系统<br>
-a 自动运行，无需在VNC里手动操作(理想情况下)<br>
-i 指定网卡，多网卡的时候需要指定，单网卡可以忽略<br>
--mirror 指定源，同地区的源装系统会更快，默认是美国源，下方为Debian源<br>
```
大陆源
--mirror 'http://mirrors.ustc.edu.cn/debian/'
香港源
--mirror 'http://ftp.hk.debian.org/debian/'
台湾源
--mirror 'http://ftp.tw.debian.org/debian/'
日本源
--mirror 'http://ftp.jp.debian.org/debian/'
韩国
--mirror 'http://ftp.kr.debian.org/debian/'
新加坡
--mirror 'http://mirror.0x.sg/debian/'
俄罗斯
--mirror 'http://ftp.ru.debian.org/debian/'
```
### [forward.sh](https://raw.githubusercontent.com/GouGoGoal/SHELL/master/forward.sh) iptables端口转发工具
使用iptables进行转发，性能最快，但不支持负载均衡，下载完成后编辑查看如何使用<br>
### 一键添加swap
```
bash <(curl -k https://raw.githubusercontent.com/GouGoGoal/SHELL/master/addswap.sh) [1024]
```
某些模板开机的Linux系统没有swap，添加swap以提高系统稳定性<br>
参数以M为单位添加，若没有参数则添加和当前RAM一样大小的swap<br>
### [BestTrace](https://raw.githubusercontent.com/GouGoGoal/SHELL/master/besttrace) 路由追踪工具
下载到Linux上，给执行权限，就可以了，besttrace [-g cn] 1.1.1.1<br>
### [TCPing](https://raw.githubusercontent.com/GouGoGoal/SHELL/master/tcping) 查看TCP延迟
下载到Linux上，给执行权限，就可以了，tcping 1.1.1.1<br>
### [SpeedTest](https://raw.githubusercontent.com/GouGoGoal/SHELL/master/speedtest) 没啥好说的，给执行权限就行了
### [Nginx](https://github.com/GouGoGoal/SHELL/tree/master/Nginx) 的使用方法技巧
### [PHP](https://github.com/GouGoGoal/SHELL/tree/master/PHP) 的apt安装以及部分优化
### [Mysql](https://github.com/GouGoGoal/SHELL/tree/master/Mysql) 的apt安装以及部分优化
### [CC脚本](https://github.com/GouGoGoal/SHELL/raw/master/cc.py) 
```
python3写的简单CC脚本，自动获取并筛选可用的socks4/5，然后进行攻击
pip3 install requests pysocks
后台运行：安装screen 创建一个新后台：screen -S cc 
运行脚本：python3 cc.py 
切入后台：Ctrl + a +d
恢复前台：screen -r cc
```
### [Telegram代理](https://raw.githubusercontent.com/GouGoGoal/SHELL/master/mtproxy.tar) 
```
wget https://raw.githubusercontent.com/GouGoGoal/SHELL/master/mtproxy.tar
tar xvf mtproxy.tar -C /root
cd /root/mtproxy
apt -y install python3 python3-pip 
pip3 install uvloop pycryptodome pycrypto
cp mtproxy.service /etc/systemd/system/
systemctl daemon-reload
systemctl start mtproxy
sleep 5s
systemctl status mtproxy
默认火力全开，若想限制请修改/etc/systemd/system/mtproxy.service
```



