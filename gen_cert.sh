#!/bin/sh

set -ex

cd keys
rm *.pem *.csr

cfssl gencert -initca ../cert_config/ca_csr.json | cfssljson -bare ca

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=../cert_config/ca_config.json \
  -profile=default \
  ../cert_config/consul_csr.json | cfssljson -bare consul
