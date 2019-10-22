Easier transparent non-Chinese server traffic redirection to v2ray, shadowsocks server.

# About

## Features
- set up v2ray servers with websocket over tls as transport layer
- set up shadowsocks-libev
- automatically obtain letsencrypt tls certificate using [caddy](https://caddyserver.com/)
- use [dns over https](https://github.com/aarond10/https_dns_proxy) and [v2ray dokodemo-door](https://v2ray.com/chapter_02/protocols/dokodemo.html) to avoid dns poisoning
- resolve Chinese domains with dirtier but possibly faster dns servers using [dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list)
- cache dns queries with dnsmasq
- connect ip addresses in [china_ip_list](https://github.com/LisonFan/china_ip_list) directly
- generate scripts to manage traffic redirection on openwrt

## Ansible roles
- v2ray-server, installing v2ray in a vps
- shadowsocks-libev-server, installing shadowsocks-libev in a vps
- v2ray-client, downloading v2ray binaries
- caddy, front-end http server, used as reverse proxy to v2ray server
- traefik, deprecated reverse proxy
- openwrt, setting up transparent proxy on openwrt

# Example usage with aws ec2

## Import ssh public key
```
key_name=my_superb_public_key
region=ap-northeast-1
aws --region "$region" ec2 import-key-pair --key-name "$key_name" --public-key-material file://~/.ssh/id_rsa.pub
```

## Create aws security group
```
aws --region "$region" ec2 create-security-group --group-name circumvent-gfw --description "circumvent gfw"
aws --region "$region" ec2 authorize-security-group-ingress --group-name circumvent-gfw --protocol tcp --port 22 --cidr 0.0.0.0/0
aws --region "$region" ec2 authorize-security-group-ingress --group-name circumvent-gfw --protocol tcp --port 80 --cidr 0.0.0.0/0
aws --region "$region" ec2 authorize-security-group-ingress --group-name circumvent-gfw --protocol tcp --port 443 --cidr 0.0.0.0/0
```

## Run ec2 instance
```
# find a new ubuntu image here https://cloud-images.ubuntu.com/locator/ec2/
aws --region "$region" ec2 run-instances --image-id ami-01213e6def4fd4853 --security-groups circumvent-gfw --key-name "$key_name"
```

## Get instance ip
Wait a moment and run
```
aws --region "$region" ec2 describe-instances
```

## Set a new a-record
In order to use tls encryption, we need a trusted tls certificate. Currently we use caddy to automatically obtain certificate from letsencrypt server (via http challenge).

## Fill in ansible hosts info
Append the following to `inventory/hosts`
```
[myRouter]
myrouter.openwrt.org

[myRouter:vars]
user=root

[myV2rayServer]
v2ray.example.com

[myV2rayServer:vars]
user=ubuntu
become=yes
letsencrypt_email=test@example.com

[myShadowsocksLibevServer]
v2ray.example.com

[myShadowsocksLibevServer:vars]
user=ubuntu
become=yes
letsencrypt_email=test@example.com
```

## Use bbr
```
ansible-playbook playbook.yml -i inventory -e role=bbr -e host=myV2rayServer
```

## Set up caddy
```
ansible-playbook playbook.yml -i inventory -e role=caddy -e host=myV2rayServer
```

## Set up v2ray-server
```
ansible-playbook playbook.yml -i inventory -e role=v2ray-server -e host=myV2rayServer
```
## Set up shadowsocks-libev-server
```
ansible-playbook playbook.yml -i inventory -e role=shadowsocks-libev-server -e host=myShadowsocksLibevServer
```

## Set up openwrt
```
ansible-playbook playbook.yml -i inventory -e role=openwrt -e host=myRouter -e server=v2ray.example.com -e program=shadowsocks-libev
```

Voilà!

# Acknowledge
I want to thank [@wzyboy](https://github.com/wzyboy) for providing the idea.

This project is built on top of following projects.
- [ansible-roles-bbr](https://github.com/devops-templates/ansible-roles-bbr)
- [caddy-ansible](https://github.com/antoiner77/caddy-ansible)
- [dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list)
- [ansible-traefik](https://github.com/kibatic/ansible-traefik)
- [shadowsocks-libev-ansible](https://github.com/vfreex/shadowsocks-libev-ansible)

# Related projects
- [kexue-gateway](https://github.com/wi1dcard/kexue-gateway/)
