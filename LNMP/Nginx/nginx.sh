#!/bin/bash

echo "适配常用Linux发行版本(CentOS、Debian、Ubuntu)，根据 https://nginx.org/en/linux_packages.html 中的步骤编写而成"
echo '旧版系统不支持tls1.3，可自行编译；国内机器执行缓慢，但一般问题不大'
seconds_left=5
while [ $seconds_left -gt 0 ];do
    echo -n "$seconds_left 后自动执行，CTRL+C可取消"
    sleep 1
    seconds_left=$(($seconds_left - 1))
    echo -ne "\r     \r" #清除本行文字
done

#根据系统版本添加官网源并安装
if [ "`grep  PRETTY_NAME /etc/os-release |grep CentOS`" ]; then
	#CentOS
	yum install -y yum-utils
	echo '[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true'>/etc/yum.repos.d/nginx.repo
	yum-config-manager --enable nginx-mainline	
	yum install -y nginx
	systemctl stop firewalld
	systemctl disable firewalld
	setenforce 0
	echo 'SELINUX=disabled'>/etc/selinux/config
elif [ "`grep  PRETTY_NAME /etc/os-release |grep Debian`" ]; then
	#Debian
	apt update
	apt install -y curl gnupg2 ca-certificates lsb-release
	echo "deb http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" >/etc/apt/sources.list.d/nginx.list
	curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
	#apt-key fingerprint ABF5BD827BD9BF62
	apt update
	apt install -y nginx
elif [ "`grep  PRETTY_NAME /etc/os-release |grep Ubuntu`" ]; then
	#Ubuntu
	apt update
	apt install -y curl gnupg2 ca-certificates lsb-release
	echo "deb http://nginx.org/packages/mainline/ubuntu `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list
	curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
	apt update
	apt install -y nginx
else 
	echo "您的Linux发行版本可能不是CentOS、Debian、Ubuntu，更换系统后再做尝试"
fi

#更改nginx默认参数，优化连接
echo 'user  root;
worker_processes  auto;
worker_cpu_affinity auto;
worker_rlimit_nofile 51200;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
	use epoll;
	multi_accept on;
	worker_connections  4096;
}
stream {
#include /etc/nginx/forward.conf;
resolver 223.5.5.5 8.8.8.8 valid=60s ipv6=off;
error_log  /var/log/nginx/forward.error.log warn;
}
http {
	include       /etc/nginx/mime.types;
	default_type  application/octet-stream;

	sendfile       on;
	tcp_nopush     on;
	tcp_nodelay    on;
	keepalive_timeout  60;
	#隐藏版本号
	server_tokens off;
	include /etc/nginx/conf.d/*.conf;
}'>/etc/nginx/nginx.conf

#重写nginx.service，避免出现Can't open PID file /var/run/nginx.pid (yet?) after start错误提示
if [ "`command -v systemctl`" != '' ]; then
	rm -rf /lib/systemd/system/nginx.service
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
[Install]
WantedBy=multi-user.target'>/etc/systemd/system/nginx.service
	systemctl daemon-reload
fi

















	