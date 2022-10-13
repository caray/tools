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
#安装Docker-compose
sudo curl -L "https://get.daocloud.io/docker/compose/releases/download/2.11.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
