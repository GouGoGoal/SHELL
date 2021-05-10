```
kcp-server -l :8091 -t 127.0.0.1:8090  --crypt none  --mode fast3 --mtu 1542 --sndwnd 10000 --rcvwnd 10000
kcp-client -l :8082 -r hinet1.10242018.xyz:8091 --crypt none --mode fast3 --mtu 1542 --sndwnd 10000 --rcvwnd 10000
--mode fast、fast2、fast3、normal 、default 从前到后速度越来越慢，流量越来越省
mode非'manual'时nodelay interval resend nc四个参数不会生效(手动修改也没啥必要)
--mtu Linux下通过 ping -s 1460 -M do baidu.com  1460+28 即最合理MTU

--sndwnd  (send)上传的包的大小，
--rcvwnd  (receive)下载的包的大小
服务端的sndwnd要和客户端的rcvwnd对应
理论速度  服务端snd/延迟 KB/S
--datashard  
--parityshard
EFC纠错，每发送datashard个包额外发送parityshard个包，适用于丢包较严重的线路
若丢包百分之10，就依次填10 1(仅供参考)
最后速度 datashard+parityshard）/ datashard * 之前算的速度=纠错后的速度
```
