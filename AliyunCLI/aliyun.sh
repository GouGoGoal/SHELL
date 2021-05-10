#!/bin/bash

DomainName="10242018.xyz"

#功能：检测某个IP对应的端口是否开放，即检测此IP是否连通
#      若开放1，若不开放输出0
#用法：available_test IP或域名 端口
function available_test()  {
i=0
while [ $i -lt 5 ];do
	if [ "`nmap $1 -p $2|grep open`" ];then	
		echo 1
	else 
		let i++
		sleep 5s
	fi
done
echo 0
}
#功能：根据端口开闭来启停解析
#用法：AutoChangeStatus 域名或IP 端口 对应的RecordID
function AutoChangeStatus() {
	x=`available_test $1 $2`
	case $x in
	0)
		if [ ! -f "/dev/shm/$1" -o "`cat /dev/shm/$1`" == 1 ];then
			aliyun alidns SetDomainRecordStatus --RecordId $3 --Status Disable
			echo '0' >/dev/shm/$1
		fi
		;;
	1)
		if [ ! -f "/dev/shm/$1" -o "`cat /dev/shm/$1`" == 0 ];then
			aliyun alidns SetDomainRecordStatus --RecordId $3 --Status Enable
			echo '1' >/dev/shm/$1
		fi
		;;
	esac
}

#	if [ "`command -v nmap`" == "" ];then
#		if [ ! -f "/etc/redhat-release" ];then
#			apt install -y nmap
#		else 
#			yum install -y nmap
#		fi
#	fi

function help() {
echo '
	aliyun.sh config 初始化配置
		list [RR] 列出当前所有解析(最多显示500个解析)，可加筛选字段
		enable/disablei/del 00000000000000000  启用/停用/删除此RecordID解析
		add A|CNAME 1.1.1.1|test.com 添加一个解析
		change 00000000000000000 1.1.1.1|test.com [A|CNAME] 更改此RecordID解析(解析类型默认不变，若想更改用最后一个参数指定)
		cron 执行预设定时任务'
}

#定时任务 
function cron() {
	#AutoChangeStatus www.baidu.com 80 1111111111111111 &
	wait
	stty echo
}


#不匹配大小
shopt -s nocasematch
case $1 in
list)
	if [ "$2" == "" ];then 
		tables="`aliyun alidns  DescribeDomainRecords --DomainName $DomainName --output cols=RR,Value,TTL,RecordId,Status rows=DomainRecords.Record[] --PageSize 500`"
		echo "$tables"|head -2
		echo "$tables"|sed '1,2d'|sort
	else 
		aliyun alidns  DescribeDomainRecords --DomainName $DomainName --output cols=RR,Value,TTL,RecordId,Status rows=DomainRecords.Record[] --PageSize 500 |grep $2|sort
	fi
	;;
enable)
	aliyun alidns SetDomainRecordStatus --RecordId $2 --Status Enable
	;;
disable)
	aliyun alidns SetDomainRecordStatus --RecordId $2 --Status Disable
	;;
add)
	if [ `echo "$2"|grep -qwi "A"` -o `echo "$2"|grep -qwi "CNAME"` ];then 
		aliyun alidns AddDomainRecord --Type $2 --DomainName $DomainName --RR $3 --Value $4
	else echo "输入有误"
	fi
	;;
del)
	aliyun alidns DeleteDomainRecord --RecordId $2
	;;
change)
	Info=`aliyun alidns DescribeDomainRecordInfo --RecordId $2`
	RR=`echo "$Info"|grep RR|awk -F '"' '{print $4}'`
	Type=`echo "$Info"|grep Type|awk -F '"' '{print $4}'`
	if [ "$4" != "" ];then
		Type=$4
	fi
	if [ `echo "$Type"|grep -qwi "A"` -o `echo "$Type"|grep -qwi "CNAME"` ];then 
		aliyun alidns UpdateDomainRecord --RecordId $2 --RR $RR --Type $Type --Value $3
	else echo '输入有误，或无对应解析'
	fi
	;;
config*)
	echo "以此输入AccessKey SecretKey 区域(随便填就行) 回车 回车"
	aliyun configure;
	;;
cron)
	cron
	;;
*)	
	help
	;;
esac
