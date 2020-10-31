#!/bin/bash
#将本机中的文件快速分发至其他的多台机器上，并执行某些命令


if [ `id -u`  != 0 ];then
	echo "请使用root用户执行!"
	exit
fi
#本地文件
Local_File='/etc/forward.sh'
#远程文件，即复制过去的路径
Remote_File='/etc/forward.sh'

#技巧：Local_File可以写多个文件，Remote_File写路径，即Local_File的文件拷贝到Remote_File路径下

#输入需要同步的VPS的SSH信息
VPS_SSH=(
#用户名@主机名 密码(如果做了免密可以不填) 端口(端口若是22，可以不填)
#'root@192.168.0.4 passwd 22'
)

#顺带要执行的命令，reload restart之类的
Command='bash /etc/forward.sh'
 
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
	if [ ! "$Port" ];then Port=22;fi
	if [ "$Local_File" ];then 
		expect -c "
			#先scp同步文件
			spawn scp -P$Port $Local_File $SSH:$Remote_File
			expect {
			\"assword\" {set timeout 300; send \"$Password\r\";}
			\"yes/no\" {send \"yes\r\"; exp_continue;}
			}
		expect eof"
	fi
	if [ "$Command" ];then 
	expect -c "		
		#再ssh执行命令
		spawn ssh $SSH -p $Port \"$Command\"
		expect {
		\"assword\" {set timeout 300; send \"$Password\r\";}
		\"yes/no\" {send \"yes\r\"; exp_continue;}
		}
	expect eof"
	fi
done
