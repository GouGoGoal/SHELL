# 安装(Debian)
```
apt install gnupg2
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
percona-release setup ps80
apt install percona-server-server
```

# 配置
默认通过apt安装后有很多连七八糟的配置文件扰人实现
可以直接清空 /etc/mysql/ 下的配置文件。重新建立一个my.cnf
```
[mysqld]
pid-file	= /var/run/mysqld/mysqld.pid
socket		= /var/run/mysqld/mysqld.sock
datadir		= /var/lib/mysql
log-error	= /var/log/mysql/error.log

#自适应参数
innodb_dedicated_server = ON
#关闭binlog
disable-log-bin
#密码传统模式
default-authentication-plugin = mysql_native_password
```

