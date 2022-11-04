#!/bin/bash

alg="ecc"
all_domain=$1
srv_key_name="server"

domain="domain.com"
san="DNS:*.${domain},DNS:${domain}"

if [ -n "${all_domain}" ]; then
    #分割域名
    OLD_IFS="$IFS"  
    IFS="," 
    domain_array=($all_domain)
    IFS="$OLD_IFS"  

    domain_len=${#domain_array[@]} 
      
    domain=${domain_array[0]}
    san=""
    for ((i=0;i<domain_len;i++))
   {
    if [ $i = 0 ];then
        san="DNS:${domain_array[i]}"
    else
        san="${san},DNS:${domain_array[i]}"
    fi
   }
fi

ca_subj="/C=CN/ST=BEIJING/L=BEIJING/O=TrustAsia TLS RSA CA/CN=TrustAsia TLS RSA CA"
server_subj="/C=CN/ST=BEIJING/L=BEIJING/O=TrustAsia TLS RSA CA/CN=${domain}"
#其中C是Country，ST是state，L是local，O是Organization，OU是Organization Unit，CN是common name
days=3650 # 有效期10年
echo "san:${san}"

sdir="certs"
ca_key_file="${sdir}/ca.key"
#ca_crt_file="${sdir}/ca.crt"
ca_crt_file="${sdir}/ca.pem"
#srv_key_file="${sdir}/${srv_key_name}.key"
srv_key_file="${sdir}/key.pem"
srv_csr_file="${sdir}/${srv_key_name}.csr"
#srv_crt_file="${sdir}/${srv_key_name}.crt"
srv_crt_file="${sdir}/cert.pem"
srv_p12_file="${sdir}/${srv_key_name}.p12"
srv_fullchain_file="${sdir}/${srv_key_name}-fullchain.crt"
cfg_san_file="${sdir}/san.cnf"


#algorithm config
if [[ ${alg} = "rsa" ]] ; then
    rsa_len=2048
elif [[ ${alg} = "ecc" ]] ; then
    ecc_name=prime256v1
else 
    usage 
    exit 1
fi     #ifend

echo "algorithm:${alg}"

mkdir -p ${sdir}

if [ ! -f "${ca_key_file}" ]; then
    echo  "------------- gen ca key-----------------------"
    if [[ ${alg} = "rsa" ]] ; then
        openssl genrsa -out ${ca_key_file} ${rsa_len}
    elif [[ ${alg} = "ecc" ]] ; then
        openssl ecparam -out ${ca_key_file} -name ${ecc_name} -genkey
    fi     #ifend
    
    openssl req -new -x509 -days ${days} -key ${ca_key_file} -out ${ca_crt_file} -subj "${ca_subj}"
fi


if [ ! -f "${srv_key_file}" ]; then
    echo  "------------- gen server key-----------------------"
    if [[ ${alg} = "rsa" ]] ; then
        openssl genrsa -out ${srv_key_file} ${rsa_len}
    elif [[ ${alg} = "ecc" ]] ; then
        openssl ecparam -genkey -name ${ecc_name} -out ${srv_key_file}
    fi     #ifend

    openssl req -new  -sha256 -key ${srv_key_file} -out ${srv_csr_file} -subj "${server_subj}"

    printf "[ SAN ]\nauthorityKeyIdentifier=keyid,issuer\nbasicConstraints=CA:FALSE\nkeyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment\nsubjectAltName=${san}" > ${cfg_san_file}
    openssl x509 -req  -days ${days} -sha256 -CA ${ca_crt_file} -CAkey ${ca_key_file} -CAcreateserial -in ${srv_csr_file}  -out ${srv_crt_file} -extfile ${cfg_san_file} -extensions SAN
    #cat ${srv_crt_file} ${ca_crt_file} > ${srv_fullchain_file}

    #openssl pkcs12 -export -inkey ${srv_key_file} -in ${srv_crt_file} -CAfile ${ca_crt_file} -chain -out ${srv_p12_file}
	cp -f ${sdir}/ca.pem ${sdir}/../
	cp -f ${sdir}/cert.pem ${sdir}/../
	cp -f ${sdir}/key.pem ${sdir}/../
    rm -rf ${sdir}
fi
