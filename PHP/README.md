### 只罗列出Debian下的教程，CentOS建议宝塔
#### 安装php以及常用组件
```
apt install php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-opcache php-zip php php-json php-bz2 php-bcmath
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