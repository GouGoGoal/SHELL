#!/bin/bash
cd /root/

#下载hysteria
if [ "`cat /proc/cpuinfo |grep -o avx2`" ];then 
	wget  https://download.hysteria.network/app/latest/hysteria-linux-amd64-avx -O /root/hysteria
else
	wget  https://download.hysteria.network/app/latest/hysteria-linux-amd64 -O /root/hysteria
fi

mv /root/hysteria /usr/sbin/hysteria
chmod +x /usr/sbin/hysteria


#创建服务
echo '[Unit]
After=rc-local.service
[Service]
Type=simple
ExecStart=/usr/sbin/hysteria server -c /etc/hysteria.yaml --log-level error
Restart=always
LimitNOFILE=51200
#调整服务CPU IO的优先级，数字越低优先级越高(可能，尚未摸清)，默认值是100
CPUWeight=100
IOWeight=100
#每10秒尝试重启服务
StartLimitBurst=0
RestartSec=10
[Install]
WantedBy=multi-user.target
' > /etc/systemd/system/hysteria.service

#生成自签证书
cd /root/
bash <(curl -k https://raw.githubusercontent.com/GouGoGoal/backend/own_xrayr/tls-gen.sh) 
#写入配置文件
echo 'listen: :443 
tls:
  cert: /root/cert.pem 
  key: /root/key.pem
  sniGuard: disable
speedTest: true  
auth:
  type: password
  password: 114514114514
  #type: userpass
  #userpass: 
    #826430292: a5d89706-451a-428d-9745-40b57aea2d59
    #junalyetwen: 22291a56-8c10-4186-a980-820c1c32dacd
#bandwidth:
#  up: 100 mbps
#  down: 100 mbps    
masquerade: 
  type: proxy
  proxy:
    url: https://www.ntppool.org/ 
    rewriteHost: true
quic:
  maxIncomingStreams: 10240 
acl:
  inline:
    #屏蔽法轮功 
    - reject(aboluowang.com)
    - reject(bannedbook.net)
    - reject(bannedbook.org)
    - reject(broadpressinc.com)
    - reject(chinaaffairs.org)
    - reject(dafahao.com)
    - reject(donatecarsoh.org)
    - reject(dongtaiwang.com)
    - reject(falundafa.org)
    - reject(falundafa.org.tw)
    - reject(falundafamuseum.org)
    - reject(falungong.club)
    - reject(faluninfo.net)
    - reject(fawanghuihui.org)
    - reject(fayuanbooks.com)
    - reject(fgmtv.org)
    - reject(ganjing.com)
    - reject(ganjingworld.com)
    - reject(guangming.org)
    - reject(mhradio.org)
    - reject(ninecommentaries.com)
    - reject(starp2p.com)
    - reject(tiandixing.org)
    - reject(tiantibooks.org)
    - reject(tuidang.org)
    - reject(upholdjustice.org)
    - reject(wujieliulan.com)
    - reject(xinsheng.net)
    - reject(yuanming.net)
    - reject(yuming.qxbbs.org)
    - reject(zhengjian.org)
    - reject(zhengwunet.org)
    - reject(zhenxiang.biz)
    - reject(zhuichaguoji.org)
    - reject(shenyun.com)
    - reject(shenyun.org)
    - reject(shenyuncreations.com)
    - reject(shenyunperformingarts.org)
    #屏蔽shadowserver
    - reject(shadowserver.org)
    #屏蔽quic
    - reject(all, udp/443)
outbounds:
  - name: v4first
    type: direct
    direct:
      mode: 46    
'>/etc/hysteria.yaml

#开机自启服务并查看状态
systemctl enable   hysteria
systemctl restart  hysteria
systemctl status   hysteria
