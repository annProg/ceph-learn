#!/bin/bash
mv /etc/yum.repos.d/* /tmp
curl -s http://mirrors.aliyun.com/repo/Centos-7.repo -o /etc/yum.repos.d/CentOS-Base.repo

rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime


value=$( grep -ic "entry" /etc/hosts )
if [ $value -eq 0 ]
then
echo "
################ cookbook host entry ############

192.168.1.101 node-1
192.168.1.102 node-2
192.168.1.103 node-3
192.168.1.104 node-4
192.168.1.105 node-5

######################################################
" >> /etc/hosts
fi
if [ -e /etc/redhat-release ]
then
yum install -y ntp ntpdate wget vim
systemctl enable ntpd
systemctl enable ntpdate
systemctl stop ntpd
systemctl stop ntpdate
ntpdate 0.centos.pool.ntp.org > /dev/null 2> /dev/null
systemctl start ntpdate
systemctl start ntpd
fi


#if [ ! -b /dev/sdb1 ];then
#	echo -e "n\np\n\n\n\nw" |fdisk /dev/sdb
#
#	mkfs.xfs /dev/sdb1
#	mkdir /data1
#	mount -t xfs /dev/sdb1 /data1
#fi
