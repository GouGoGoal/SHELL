### 只罗列出Debian下的教程，CentOS建议宝塔
#安装新版php
```
apt-get install ca-certificates apt-transport-https software-properties-common wget curl lsb-release -y
curl -sSL https://packages.sury.org/php/README.txt |bash -x
apt update
apt install libapache2-mod-fcgid php8.2 php8.2-common php8.2-cli php8.2-fpm php8.2-gd php8.2-mysql php8.2-mbstring php8.2-curl php8.2-xml php8.2-xmlrpc php8.2-zip php8.2-intl php8.2-bz2 php8.2-bcmath php8.2-redis php8.2-swoole4  php8.2-readline  php8.2-event
```
#### 安装php以及常用组件
```
#安装必要组件
apt install php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-opcache php-zip php php-json php-bz2 php-bcmath
systemctl status php7.4-fpm
```

#### 四条命令删除PHP配置文件中的注释与空行，配置解释建议直接网上搜，注释参考起来有困难
```
for i in `find /etc/php/ -name "*.ini"`;do sed -i '/^;.*/d' $i;done
for i in `find /etc/php/ -name "*.ini"`;do sed -i /^[[:space:]]*$/d $i;done
for i in `find /etc/php/ -name "*.conf"`;do sed -i '/^;.*/d' $i;done
for i in `find /etc/php/ -name "*.conf"`;do sed -i /^[[:space:]]*$/d $i;done
```
#### 优化opcache扩展
```
vi /etc/php/7.3/fpm/conf.d/10-opcache.ini 
添加以下行
opcache.memory_consumption=128
opcache.max_accelerated_files=4000
opcache.file_cache_only=false
opcache.interned_strings_buffer = 16
```
依次解释<br>
设置多少内存缓存opcode,单位M。如果内存不够用，就会出现一些php文件缓存不到的情况。解决办法是设置缓存到文件中去<br>
最大允许缓存多少个php文件,需要根据项目的文件数来定。这个值一定要比 PHP 应用中的文件数大。最大支持100万个文件<br>
设置:是不是只使用文件来缓存opcode,不使用内存缓存。建议:关掉。最好内存和文件都同时使用<br>
字符串驻留技术使用多少内存，设置为8M,这是默认值<br>

# 禁用函数
为了安全起见，一般会禁用掉下方函数，还有个 system (此函数我用到了，故没禁用)
```
disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wifcontinued,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_get_handler,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,pcntl_async_signals,passthru,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server
```

```
cat /etc/php/7.3/fpm/pool.d/web.conf

[www]
user = web
group = web
listen = /run/php/php7.3-fpm.sock
listen.owner = web
listen.group = web

;和其他服务部署在一起，设为dynamic时仅下三个参数生效
;pm = dynamic
;动态下起始进程数
pm.start_servers = 5
;最小进程数
pm.min_spare_servers = 5
;最大进程数
pm.max_spare_servers = 24

;如果一台机器只跑PHP(或内存空余较多)，设为static时仅下一个参数生效，大概按每个进程占用25M计算
pm = static
;静态模式下进程数量
pm.max_children = 35
```


#安装ioncube
```
https://www.ioncube.com/loaders.php 下载iocube后将指定文件放至 /usr/lib/php/xxx/ 里

```

