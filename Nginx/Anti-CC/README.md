### 工作流程
监听nginx指定时间间隔(默认10秒)内的访问日志，筛选出来访IP并计数排序<br>
若某个IP10秒内的访问次数超过了阈值，且没有位于白名单中，旧上报CloudFlare进行封禁(或通过iptables ban掉)
### 使用方法
将CloudFlare_BlackIP.sh放至某个目录并修改为你喜欢的名字，按如下示例创建systemd服务文件<br>
```
echo "[Unit]
Description=CF_BlackIP
After=rc-local.service
[Service]
Type=simple
ExecStart=bash /etc/nginx/CF_BlackIP.sh
Restart=always
[Install]
WantedBy=multi-user.target">/etc/systemd/system/CF_BlackIP.service
```
编辑CF_BlackIP.sh，将CloudFlare的相关信息，以及监听的日志，拉黑模式等进行修改<br>
bash -x CF_BlackIP.sh 看不到错误信息，然后systemctl start|enable CF_BlackIP 启动|开机自启 此服务

### 白名单设置方法
同样将whiteip.sh放至某个目录并修改为你喜欢的名字，填入白名单域名，其他的一般不需要更改<br>
然后按如下示例添加一条定时任务即可
```
echo '0/5 * * * * root bash bash /etc/nginx/whiteip.sh'>/etc/crontab
```
#### 若误报较多可将CloudFlare_BlackIP.sh中的阈值调整的再大一些，也可以将模式改为challenge|js_challenge，即验证码|五秒盾模式