#/bin/bash
#CloudFlare邮箱
CFEMAIL="***@gmail.com"
# 填CloudFlare API key
CFAPIKEY="**********"
#域名对应的ZonesID
ZONESID="**********"

#监听哪个日志用以分析黑名单，根据实际修改
logfile=/var/log/nginx/access.log
#将IP提取到此文件，如果有多个网站请将此处修改成唯一值
echofile=/tmp/black_list
#黑名单IP列表，如果有多个网站请将此处修改成唯一值
blackip=/tmp/black_ips
#分析近几分钟的请求，计划任务频率根据此值适配，此处填1就每一分钟执行，填2就每两分钟执行
last_minutes=1 
#阈值，大概可以选择一分钟60次，同时根据上方的频率一起修改
times=10



start_time=`date +"%Y-%m-%dT%H:%M"`
stop_time=`date -d "$last_minutes minutes ago" +"%Y-%m-%dT%H:"%M""`

#过滤出单位之间内的日志并统计最高ip数，请替换为你的日志路径，日志切割格式可能需要根据场景修改，此处根据下方格式输出
#    定义访问日志       #请求头传递源地址      #请求地址     #状态    #处理时长      #本地时间      #请求地址   #请求的url#请求浏览器信息
#	log_format  access  $http_x_forwarded_for--$remote_addr--$status--$request_time--$time_iso8601--$http_host--$request--$http_user_agent;
#本脚本根据“请求头传递源地址”进行分析
sed -n "/$stop_time/,/$start_time/p" $logfile|awk -F '--' '{print $1}' | sort | uniq -c | sort -nr >$echofile
ip_top=`cat $echofile | head -1 | awk '{print $1}'`
ip=`cat $echofile | awk '{if($1>'$times')print $2}'`
for line in $ip
do
echo $line >> $blackip
#if [ "$line" != "1.1.1.1" ];then  #如果需要添加白名单，请取消此处注释
curl -s -o /dev/null -X POST \
    "https://api.cloudflare.com/client/v4/zones/$ZONESID/firewall/access_rules/rules" \
    -H "X-Auth-Email: $CFEMAIL" \
    -H "X-Auth-Key: $CFAPIKEY" \
    -H "Content-Type: application/json" \
    --data '{"mode":"block","configuration":{"target":"ip","value":"'$line'"},"notes":"脚本自动上报"}'   
echo "$line $last_minutes分钟内访问站点大于$times次，已上报拉黑"
#fi
done
rm -rf $echofile
rm -rf $blackip
