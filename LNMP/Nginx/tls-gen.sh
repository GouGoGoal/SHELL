#!/bin/bash
rm -f cert.pem cert.key
rm -f ca.key ca.csr
rm -f cert.csr san.cnf
domain="oss-`head /dev/urandom | tr -dc a-z0-9 | head -c 8`.w.kunlunsl.com"
san="DNS:kunlunsl.com"

ca_subj="/CN=GlobalSign Organization Validation CA - SHA256 - G2/C=BE/O=GlobalSign nv-sa"
server_subj="/CN=kunlunsl.com/O=Alibaba (China) Technology Co., Ltd./L=HangZhou/ST=ZheJiang/C=CN"
#其中C是Country，ST是state，L是local，O是Organization，OU是Organization Unit，CN是common name
days=365 # 有效期1年

#生成“证书颁发机构”私钥
openssl ecparam -out ca.key -name prime256v1 -genkey
#通过私钥生成“证书颁发机构”证书
openssl req -new -x509 -days ${days} -key ca.key -out ca.csr -subj "${ca_subj}"

#通过“证书颁发机构”生成TLS私钥
openssl ecparam -genkey -name prime256v1 -out key.pem
#通过“证书颁发机构”生成TLS证书
openssl req -new -sha256 -key key.pem -out cert.csr -subj "${server_subj}"
	
printf "[ SAN ]\nauthorityKeyIdentifier=keyid,issuer\nbasicConstraints=CA:FALSE\nkeyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment\nsubjectAltName=${san}" > san.cnf
openssl x509 -req  -days ${days} -sha256 -CA ca.csr -CAkey ca.key -CAcreateserial -in cert.csr  -out cert.pem -extfile san.cnf -extensions SAN

rm -f ca.key ca.csr
rm -f cert.csr san.cnf
