### nginx一键安装脚本
使用Nginx官方主线安装nginx，旧系统(openssl版本小于1.1.1)的不支持tlsv1.3，可以执行完此脚本后手动编译<br>
```
curl -k https://raw.githubusercontent.com/GouGoGoal/SHELL/master/Nginx/nginx.sh|bash
```
### [配置解析](https://github.com/GouGoGoal/SHELL/blob/master/Nginx/nginx.conf)
### jump.html 在页面停留几秒然后跳转至另一网址，类似于小电影网址
### 转发动态域名<br>
需要转发很多动态域名时，常常因为DNS解析超时而导致nginx启动失败<br>
而且当DNS改变时，nginx不会主动解析新的IP，必须reload<br>
故设计一个脚本来辅助nginx完成功能,将nginx_helper.sh拷贝至/etc/nginx/，并进行编辑，添加自己需要转发的域名<br>
该脚本会自动进行解析并添加到 /etc/hosts 中，而当DNS变化时会调整hosts并重载nginx<br>
如下添加定时任务即可<br>
```
echo "* * * * * root flock -xn /tmp/hosts.lock -c 'bash /etc/nginx/nginx_helper.sh'">>/etc/crontab
```
### 如何编译nginx<br>
1、在 https://nginx.org/en/download.html 下载最新版本的nginx源码并解压<br>
2、在 https://github.com/openssl/openssl/releases 下载openssl1.1.1版本的源码并解压<br>
3、安装必要的编译工具<br>
apt -y install gcc make libpcre3 libpcre3-dev zlib1g-dev<br>
或者<br>
yum -y install gcc pcre pcre-devel zlib zlib-devel<br>
4、查看当前安装的nginx的编译参数 nginx -V，默认如下<br>
```
--prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-g -O2 -fdebug-prefix-map=/data/builder/debuild/nginx-1.19.2/debian/debuild-base/nginx-1.19.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie'
```
5、进入解压好后nginx源码的路径 执行 ./configure  --prefix=/etc/nginx …(上边那一串)…--as-needed -pie' --with-openssl=./openssl-OpenSSL_1_1_1g<br>
最后添加的是解压后的openssl源码的路径<br>
5、make -j 全速编译，完成后生成 ./objs/nginx ，执行./objs/nginx -V ，看是否是你编译的版本<br>
6、备份原nginx的二进制文件 cp /usr/sbin/nginx  /usr/sbin/nginx.bak<br>
7、停掉现在的nginx服务，然后替换 cp ./objs/nginx /usr/sbin/nginx ，之后重启nginx，替换完毕<br>


### 自用的nginx，用于TCP/UDP转发
添加了upstream主动健康检查模块：项目地址以及使用方法[ngx_healthcheck_module](https://github.com/zhouchangxun/ngx_healthcheck_module)
将下载，解压，进入目录给执行权限
```
unzip nginx-1.19.2.zip && cd nginx-1.19.2
chmod +x configure openssl-OpenSSL_1_1_1g/config pcre-8.44/configure
./configure \
--with-cpu-opt=amd64 \
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--pid-path=/var/run/nginx.pid \
--error-log-path=/var/log/nginx/error.log \
--with-stream \
--with-stream_ssl_module \
--with-stream_realip_module \
 --with-stream_ssl_preread_module \
--without-select_module \
--without-poll_module \
--without-http_gzip_module \
--with-openssl=./openssl-OpenSSL_1_1_1g \
--add-module=./ngx_healthcheck_module \
--with-pcre=./pcre-8.44 
make -j
```
http模块功能是不需要添加的，奈何禁用http再添加主动健康检查这个模块编译不过去，又看不懂代码，只能CTRL+C这样子才能维持的了生活<br>
如果./configure pcre这里出错了，可以改为 --with-pcre，使用系统安装的pcre，有兴趣排错也可以
