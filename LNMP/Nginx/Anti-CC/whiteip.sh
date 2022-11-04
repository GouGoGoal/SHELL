#!/bin/bash

#空格分隔，域名或IP都可
whitelist=(www.baidu.com www.google.com)
#解析完成后生成的文件名
genfile=/dev/shm/whiteip

#删除旧的解析文件
rm -rf $genfile
#数组中的域名进行解析
for i in ${whitelist[*]}
do
	{
	if [ ! "`echo $i|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'`" ];then
		echo  "`host $i|grep -E -o \"([0-9]{1,3}[\.]){3}[0-9]{1,3}\"|head -1`">>$genfile
	else echo "$i">>$genfile
	fi
	}&
done
#等待解析完毕
wait
