
ASN=$1
if [ $ASN == "" ];then 
	echo "执行时请添加参数"
else
	echo "`curl -s https://whois.ipip.net/$ASN|grep $ASN|grep -o -E '([0-9]{1,3}[\.]){3}[0-9]{1,3}/[0-9]{1,2}'|sort|uniq`" >$ASN.ip
fi
