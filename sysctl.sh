#!/bin/bash
#常用的内核调优参数
echo '
#关闭IPV6，如果需要IPV6就注释掉然后重启
net.ipv6.conf.all.disable_ipv6=1
#开启BBR，内核支持下有效
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
#开启内核转发，用于iptables转发
net.ipv4.ip_forward=1
#优先使用ram
vm.swappiness=0
#可以分配所有物理内存
vm.overcommit_memory=1
#表示单个进程较大可以打开的句柄数
fs.file-max=512000
#表示内核套接字接受缓存区较大大小
net.core.rmem_max=67108864
#表示内核套接字发送缓存区较大大小
net.core.wmem_max=67108864
#当网卡接收数据包的速度大于内核处理速度时，会有一个列队保存这些数据包。这个参数表示该列队的较大值
net.core.netdev_max_backlog=250000
#调节系统同时发起的TCP连接数
net.core.somaxconn=4096
#与性能无关。用于解决TCP的SYN攻击
net.ipv4.tcp_syncookies=1
#开启后TCP拥塞窗口会在一个RTO时间空闲之后重置为初始拥塞窗口(CWND)大小
net.ipv4.tcp_slow_start_after_idle=0
#开启重用，允许将TIME_WAIT socket用于新的TCP连接。默认为0，表示关闭。
net.ipv4.tcp_tw_reuse=1
#表示如果套接字由本端要求关闭，这个参数决定了它保持在FIN-WAIT-2状态的时间。
net.ipv4.tcp_fin_timeout=30
#表示当keepalive起用的时候，TCP发送keepalive消息的频度。缺省是2小时，改为2分钟。
net.ipv4.tcp_keepalive_time=120
#用于向外连接的端口范围。缺省情况下很小：32768到61000，改为1024到65000。
net.ipv4.ip_local_port_range=1024 65000
#表示SYN队列的长度，默认为1024，加大队列长度为8192，可以容纳更多等待连接的网络连接数。
net.ipv4.tcp_max_syn_backlog=8192
#表示系统同时保持TIME_WAIT套接字的最大数量
net.ipv4.tcp_max_tw_buckets=5000
net.ipv4.tcp_fastopen=3
#启用有选择的应答，让发送者只发送丢失的报文段，会增加对CPU的占用
net.ipv4.tcp_sack=1
#启用RFC 1323定义的window scaling，要支持超过64KB的TCP窗口，必须启用该值（1表示启用），TCP窗口最大至1GB，TCP连接双方都启用时才生效。
net.ipv4.tcp_window_scaling=1
#MTU探测，1表示默认禁用，ping不通的时候会调整
net.ipv4.tcp_mtu_probing=1
#定义了TCP接收缓存（用于TCP接收滑动窗口）的最小值、默认值、最大值。
net.ipv4.tcp_rmem=4096 131072 16777216
#定义了TCP发送缓存（用于TCP发送滑动窗口）的最小值、默认值、最大值
net.ipv4.tcp_wmem=4096 131072 16777216
#表示TCP栈应该如何反映内存使用，分别为无压力，有压力，最大压力
net.ipv4.tcp_mem=177888 436600 16777216
#开启TCP的显式拥塞通知
net.ipv4.tcp_ecn=1
#追踪表优化
net.netfilter.nf_conntrack_tcp_timeout_fin_wait=30
net.netfilter.nf_conntrack_tcp_timeout_time_wait=30
net.netfilter.nf_conntrack_tcp_timeout_close_wait=15
net.netfilter.nf_conntrack_tcp_timeout_established=60
net.netfilter.nf_conntrack_tcp_timeout_syn_sent=30
net.netfilter.nf_conntrack_tcp_timeout_fin_wait=30
#下列根据实际调整
#net.netfilter.nf_conntrack_buckets=40960
#net.netfilter.nf_conntrack_max=1048576
#net.nf_conntrack_max=1048576
'>/etc/sysctl.conf
sysctl -p