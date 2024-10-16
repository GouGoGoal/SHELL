#/bin/bash
#CloudFlare邮箱
CFEMAIL="test@gmail.com"
# 填CloudFlare API key
CFAPIKEY="1111"
#域名对应的ZonesID
ZONEID="1111"
#监听哪个日志用以分析黑名单，根据实际修改
logfile=/var/log/nginx/test.access.log
#临时文件生成
tmpfile=/dev/shm/$ZONEID
#白名单IP列表文件，一行一个，若是动态IP可以使用whiteip.sh
#whiteip=/dev/shm/whiteip
#每隔多少秒分析一次，无需更改
cron=10s
#阈值
times=30
#上方两个参数意义，即$cron秒内，若某IP访问次数超过了$times次，视为恶意IP，白名单IP除外
#模式 block challenge whitelist js_challenge
mode=block

#过滤出单位之间内的日志并统计最高ip数
function Access_IP() {
	#    定义访问日志       #请求头传递源地址      #请求地址     #状态    #处理时长      #本地时间      #请求地址   #请求的url#请求浏览器信息
	#	log_format  access  $http_x_forwarded_for--$remote_addr--$status--$request_time--$time_iso8601--$http_host--$request--$http_user_agent;
	#下方命令根据上方日志格式而来，不同日志格式不同的筛选方法
	echo "`awk -F '--' '{print $1}' $1|sort|uniq -cd|sort -nr`"
}

#删除可能遗留的临时文件
rm -rf $tmpfile
#开始循环监听
for ((;;)) 
do
	#监听日志
	tail -f $logfile >$tmpfile &
	#等待指定秒数
	sleep $cron
	#停止监听
	kill $!

	#根据“请求头传递源地址”进行分析
	accessip=`Access_IP $tmpfile`
	#如果单IP最大访问次数小于等于$times就直接退出脚本
	if [ "`echo $accessip|awk '{print $1}'|head -1`" -lt "$times" ];then continue;fi
	#如果IP访问次数大于等于$times就保存变量
	ip=`echo "$accessip"|awk '{if($1>'$times')print $2}'`

	#删除白名单中的IP
	if [ -f $whiteip ];then 
		for i in `cat $whiteip`;do ip=`echo "$ip"|sed "/$i/d"`;done
	fi

	#将上方记录的IP都统统拉黑
	for j in $ip
	do
	{
		curl -s -X POST \
   			"https://api.cloudflare.com/client/v4/zones/$ZONEID/firewall/access_rules/rules" \
    			-H "X-Auth-Email: $CFEMAIL" \
    			-H "X-Auth-Key: $CFAPIKEY" \
    			-H "Content-Type: application/json" \
    			--data "{\"mode\":\"$mode\",\"configuration\"":{\""target\":\"ip\",\"value\":\"$j\"},\"notes\":\"脚本自动上报\"}"
		echo "$line $last_minutes分钟内访问站点大于等于$times次，已上报拉黑"
	}&
		#iptables -I INPUT -s $ip -j DROP   #若是没有套CF，通过此命令屏蔽IP
		#若想解禁执行 iptables -F INPUT
	done
	#等待上方循环结束
	wait
	#删除缓存文件
	rm -rf $tmpfile
done

