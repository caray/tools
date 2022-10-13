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
echo "Port 22222" >> /etc/ssh/sshd_config


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

