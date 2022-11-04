#!/bin/bash

wget https://raw.githubusercontent.com/GouGoGoal/SHELL/master/LNMP/Nginx/nginx -O /usr/sbin/nginx
chmod +x /usr/sbin/nginx 

mkdir /var/log/nginx
mkdir /etc/nginx

echo '[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target
[Service]
Type=forking
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/usr/sbin/nginx -s stop
#每10秒尝试重启服务
StartLimitBurst=0
RestartSec=10
Nice=-1
LimitNOFILE=51200
[Install]
WantedBy=multi-user.target' >/etc/systemd/system/nginx.service


wget  https://github.com/GouGoGoal/SHELL/raw/master/LNMP/Nginx/ng_helper.sh -O /etc/nginx/ng_helper.sh
echo "* * * * * root flock -xn /dev/shm/hosts.lock -c 'bash /etc/nginx/ng_helper.sh'" >> /etc/crontab

wget https://github.com/GouGoGoal/SHELL/raw/master/LNMP/Nginx/ipv6.xtls.conf  -O /etc/nginx/ipv6.xtls.conf
wget https://github.com/GouGoGoal/SHELL/raw/master/LNMP/Nginx/ipv6.nginx.conf -O /etc/nginx/nginx.conf
bash /etc/nginx/ng_helper.sh
systemctl enable nginx 
systemctl start nginx 


