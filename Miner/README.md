# 炒币是不可能炒币的，这辈子也不可能炒币的


```
/etc/systemd/system/xmr.service

[Unit]
Description=Miner-xmr Service
After=rc-local.service

[Service]
Type=simple
ExecStart=/usr/sbin/xmrig --api-worker-id cu-liantong --http-host 0.0.0.0 --http-enabled -o xmr-asia1.nanopool.org:14444 -u 85RWWU8kc5ZMYcnQ1Pg96cdnfNdzWQxojHz8LHWhDXefHS6PcfSHmGjSBW2b8ydLgxb668mo2LxYKexkVme1uCAV6CRcwgm -k --coin monero -a rx/0
Restart=always
#CPU限制50
CPUQuota=50%
[Install]
WantedBy=multi-user.target
```