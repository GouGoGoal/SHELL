# 炒币是不可能炒币的，这辈子也不可能炒币的


```
wget -P /usr/sbin https://github.com/GouGoGoal/SHELL/raw/master/Miner/xmrig 
chmod +x /usr/sbin/xmrig 
vi /etc/systemd/system/xmr.service

[Unit]
Description=Miner-xmr Service
After=rc-local.service

[Service]
Type=simple
ExecStart=/usr/sbin/xmrig -o us-west.minexmr.com:4444 -u 85RWWU8kc5ZMYcnQ1Pg96cdnfNdzWQxojHz8LHWhDXefHS6PcfSHmGjSBW2b8ydLgxb668mo2LxYKexkVme1uCAV6CRcwgm -k --coin monero -a rx/0
Restart=always
#CPU限制50
CPUQuota=50%
[Install]
WantedBy=multi-user.target
```


sed -i 's|xmr-asia1.nanopool.org:14444|us-west.minexmr.com:4444|' /etc/systemd/system/xmr.service
systemctl daemon-reload
systemctl restart xmr
