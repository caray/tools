#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#=================================================
#	System Required: CentOS 6/7
#	Description: 系统初始化
#	Version: 1.0
#	Author: caray
#=================================================
clear
echo ""
echo "###########################################"
echo "#        Centos Init.                     #"
echo "#      Intro: https://www.caray.cn        #"
echo "#      Author: caray                      #"
echo "###########################################"
echo ""


sh_ver="1.0"
github="raw.githubusercontent.com/caray/tools/master"


#Disable SeLinux
if [ -s /etc/selinux/config ]; then
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi


#安装基础
yum install -y vim




#修改时区
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
yum -y install chrony


#安装防火墙
yum install -y firewalld
systemctl enable firewalld
systemctl start firewalld

firewall-cmd --zone=public --add-port=22222/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent 
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload

#安装密钥
if [ ! -f "${HOME}/.ssh/authorized_keys" ]; then
	echo "Info: ~/.ssh/authorized_keys is missing ...";

	echo "Creating ${HOME}/.ssh/authorized_keys ..."
	mkdir -p ${HOME}/.ssh/
	touch ${HOME}/.ssh/authorized_keys

	if [ ! -f "${HOME}/.ssh/authorized_keys" ]; then
		echo "Failed to create SSH key file"
	else
		echo "Key file created, proceeding..."
	fi
fi

#get key from server
curl -D /tmp/headers.txt https://raw.githubusercontent.com/caray/tools/main/id_rsa.pub >/tmp/key.txt 2>/dev/null
HTTP_CODE=$(sed -n 's/HTTP\/1\.[0-9] \([0-9]\+\).*/\1/p' /tmp/headers.txt | tail -n 1)
if [ $HTTP_CODE -ne 200 ]; then
	echo "Error: server went away"; exit 1;
fi
PUB_KEY="$(cat /tmp/key.txt)"

if [ "${PUB_KEY}" = '0' ]; then
	echo "Error: Key wasn't found"; exit 1;
fi

if [ $(grep -m 1 -c "${PUB_KEY}" ${HOME}/.ssh/authorized_keys) -eq 1 ]; then
	echo 'Warning: Key is already installed'; exit 1;
fi

#install key
echo -e "\n${PUB_KEY}\n" >> ${HOME}/.ssh/authorized_keys
rm -rf /tmp/key.txt
rm -rf /tmp/headers.txt
echo 'Key installed successfully'
echo 'Thanks, Key Installer'

#禁止密码登录
sed -i "s#PasswordAuthentication yes#PasswordAuthentication no#g" /etc/ssh/sshd_config
service sshd restart

#安装Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker
#安装Docker-compose
curl -L "https://github.com/docker/compose/releases/download/v2.11.2/docker-compose-$(uname -s| tr '[:upper:]' '[:lower:]')-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

#docker使用firewalld

firewall-cmd --add-masquerade --permanent 
# Removing DOCKER-USER CHAIN (it won't exist at first)
firewall-cmd --permanent --direct --remove-chain ipv4 filter DOCKER-USER

# Flush rules from DOCKER-USER chain (again, these won't exist at first; firewalld seems to remember these even if the chain is gone)
firewall-cmd --permanent --direct --remove-rules ipv4 filter DOCKER-USER

# Add the DOCKER-USER chain to firewalld
firewall-cmd --permanent --direct --add-chain ipv4 filter DOCKER-USER

firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 0 -i docker0 -j ACCEPT -m comment --comment "allows incoming from docker"
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 0 -i docker0 -o eth0 -j ACCEPT -m comment --comment "allows docker to eth0"
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT -m comment --comment "allows docker containers to connect to the outside world"
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 0 -j RETURN -s 172.17.0.0/16 -m comment --comment "allow internal docker communication"

## 你可以直接允許來自特定 IP 的所有流量
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 0 -s 10.10.10.0/24 -j ACCEPT 
firewall-cmd --permanent --direct --add-rule ipv4 filter DOCKER-USER 0 -j REJECT --reject-with icmp-host-unreachable -m comment --comment "reject all other traffic"
firewall-cmd --reload

#bbr加速
wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
