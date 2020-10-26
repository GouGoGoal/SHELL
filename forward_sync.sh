#!/bin/bash
#和forward.sh脚本配合使用，用于多台Linux的转发规则进行同步，以负载均衡和高可用
if [ `id -u`  != 0 ];then
	echo "请使用root用户执行!"
	exit
fi
#同步文件
Sync_File='/etc/forward.sh'

#输入需要同步的VPS的SSH信息
VPS_SSH=(
#用户名@主机名 密码(如果做了免密可以不填)  -P端口(端口若是22，可以不填)
#"root@192.168.0.4 passwd -P22"
)
#删除目前存储的机器公钥
rm -rf /root/.ssh/known_hosts
#检测是否有expect指令，如果没有就装一下
if [ "`command -v expect`" == "" ]; then
    if [ ! -f "/etc/redhat-release" ]; then
        apt install -y expect
    else 
		yum install -y expect
    fi
fi


for i in "${!VPS_SSH[@]}"
do
SSH=`echo "${VPS_SSH[$i]}"|awk '{print $1}'`
Password=`echo "${VPS_SSH[$i]}"|awk '{print $2}'`
Port=`echo "${VPS_SSH[$i]}"|awk '{print $3}'`
expect -c "
spawn scp $Port $Sync_File $SSH:$Sync_File
expect {
\"assword\" {set timeout 300; send \"$Password\r\";}
\"yes/no\" {send \"yes\r\"; exp_continue;}
}
expect eof"
done
