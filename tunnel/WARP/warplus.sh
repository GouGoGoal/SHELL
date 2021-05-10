#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin && export PATH
#提前修改此参数
device_id='025d00d2-139d-47c2-a1ec-cc191544b39b'
########

while true
do
    [[ $i == 0 ]] && sleep_try=30 && sleep_min=20 && sleep_max=600 && echo $(date) Mission $flowdata GB
    install_id=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 22) && \
    curl -X POST -m 10 -sA "okhttp/3.12.1" -H 'content-type: application/json' -H 'Host: api.cloudflareclient.com' \
    --data "{\"key\": \"$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 43)=\",\"install_id\": \"$install_id\",\"fcm_token\": \"APA91b$install_id$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 134)\",\"referrer\": \"$device_id\",\"warp_enabled\": false,\"tos\": \"$(date -u +%FT%T.$(tr -dc '0-9' </dev/urandom | head -c 3)Z)\",\"type\": \"Android\",\"locale\": \"en_US\"}" \
    --url "https://api.cloudflareclient.com/v0a$(shuf -i 100-999 -n 1)/reg" | grep -qE "referral_count\":1" && status=0 || status=1
    # cloudflare限制了请求频率,目前测试大概在20秒,失败时因延长sleep时间
    [[ $sleep_try > $sleep_max ]] && sleep_try=300
    [[ $sleep_try == $sleep_min ]] && sleep_try=$((sleep_try+1))
    [[ $status == 0 ]] && sleep_try=$((sleep_try-1)) && sleep $sleep_try && rit[i]=$i && echo -n $i-o- && continue
    [[ $status == 1 ]] && sleep_try=$((sleep_try+2)) && sleep $sleep_try && bad[i]=$i && echo -n $i-x- && continue
done
