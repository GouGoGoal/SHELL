```
## 服务端
tinyvpn_amd64 -s -l 0.0.0.0:333 --mode 0 --disable-obscure --disable-fec  --tun-dev tinyfec-1 --sub-net 192.168.33.1

## 客户端
tinyvpn_amd64 -c -r 1.1.1.1:333 --mode 0 --disable-obscure --disable-fec  --tun-dev tinyfec-1 --sub-net 192.168.33.1 --keep-reconnect
```

