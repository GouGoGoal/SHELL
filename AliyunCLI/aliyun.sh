#!/bin/bash

domain=test.com
#检测某个IP对应的端口是否开放，即检测此IP是否连通，正常返回1，不正常返回0，使用此函数请先安装nmap
function available_test()  {
i=0
while [ $i -lt 5 ];do
	if [ "`nmap $1 -p $2|grep open`" == "" ];then	
		let i++
		sleep 5s
	else 
		return 1;
	fi
done
return 0;
}
#	if [ "`command -v nmap`" == "" ];then
#		if [ ! -f "/etc/redhat-release" ];then
#			apt install -y nmap
#		else 
#			yum install -y nmap
#		fi
#	fi

function help() {
echo "
	aliyun.sh config 初始化配置
	aliyun.sh list [RR] 列出当前所有解析(最多显示500个解析)
			若有第二参数则筛选出与第二个参数有关的解析
	aliyun.sh enable/disable 00000000000000000  停用或启用此RecordID解析
	aliyun.sh cron 执行预设定时任务"
}

function cron() {
	#检测22端口是否连通，若没有就自动停掉对应的解析
	available_test test.test.com 22  
	if [ "$?" == "0" ];then 
		aliyun alidns SetDomainRecordStatus --RecordId 00000000000000000 --Status Disable
	fi
}


#不匹配大小写
shopt -s nocasematch
case $1 in
list)
	if [ "$2" == "" ];then 
		aliyun alidns  DescribeDomainRecords --DomainName $domain --output cols=RR,TTL,RecordId,Status,Value rows=DomainRecords.Record[] --PageSize 500
	else 
		aliyun alidns  DescribeDomainRecords --DomainName $domain --output cols=RR,TTL,RecordId,Status,Value rows=DomainRecords.Record[] --PageSize 500 |grep $2
	fi
	;;
enable|disable)
	if [ "$1" == "enable" ];then 
		aliyun alidns SetDomainRecordStatus --RecordId $2 --Status Enable
	elif [ "$1" == "disable" ];then
		aliyun alidns SetDomainRecordStatus --RecordId $2 --Status Disable
	else 
		help
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













