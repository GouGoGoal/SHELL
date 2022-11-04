#!/bin/bash
#安装静态版本nginx

mkdir /etc/nginx
mkdir /var/log/nginx

wget -P /usr/sbin https://raw.githubusercontent.com/GouGoGoal/SHELL/master/Nginx/nginx
chmod +x /usr/sbin/nginx

wget -P /etc/nginx https://raw.githubusercontent.com/GouGoGoal/SHELL/master/Nginx/ng_helper.sh
echo "* * * * * root flock -xn /dev/shm/hosts.lock -c 'bash /etc/nginx/ng_helper.sh'" >> /etc/crontab

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
systemctl enable nginx