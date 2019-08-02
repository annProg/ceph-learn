#!/bin/bash
mv /etc/yum.repos.d/* /tmp
[ -f /tmp/puppet6.repo ] && mv /tmp/puppet6.repo /etc/yum.repos.d
[ -f /tmp/elrepo.repo ] && mv /tmp/elrepo.repo /etc/yum.repos.d
curl -s http://mirrors.aliyun.com/repo/Centos-7.repo -o /etc/yum.repos.d/CentOS-Base.repo

# puppet
#rpm -Uvh https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
#yum install -y puppetserver --enablerepo=puppet6

# 使用最新内核
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
rpm -qa |grep "kernel-ml" || yum --enablerepo=elrepo-kernel install -y kernel-ml kernel-ml-devel
grub2-set-default 0
sed -i 's/DEFAULTKERNEL=.*/DEFAULTKERNEL=kernel-ml/g' /etc/sysconfig/kernel
sed -i 's/enabled=.*/enabled=1/g' /etc/yum.repos.d/elrepo.repo

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

# Note 主机名应该解析为网络 IP 地址，而非回环接口 IP 地址（即主机名应该解析成非 127.0.0.1 的IP地址）。如果你的管理节点同时也是一个 Ceph 节点，也要确认它能正确解析自己的主机名和 IP 地址（即非回环 IP 地址）。
sed -i '/^127.0.0.1.*node/d' /etc/hosts

if [ -e /etc/redhat-release ]
then
yum install -y ntp ntpdate wget vim btrfs-progs
systemctl enable ntpd
systemctl enable ntpdate
systemctl stop ntpd
systemctl stop ntpdate
ntpdate 0.centos.pool.ntp.org > /dev/null 2> /dev/null
systemctl start ntpdate
systemctl start ntpd
fi

declare -A DEVICE
DEVICE=(
	[sdb]=data1
	[sdc]=data2
	[sdd]=data3
)

for sd in ${!DEVICE[@]};do
	if [ ! -b /dev/${sd}1 ];then
		echo -e "\033[31m$sd ${DEVICE[$sd]}[0m"
		echo -e "n\np\n\n\n\nw" |fdisk /dev/$sd

		mkfs.btrfs /dev/${sd}1
		directory=/${DEVICE[$sd]}
		[ ! -d $directory ] && mkdir $directory
		mount -t btrfs /dev/${sd}1 $directory
	fi
done


# ceph repo

cat > /etc/yum.repos.d/ceph.repo <<EOF
[ceph]
name=Ceph packages for $basearch
baseurl=https://mirrors.aliyun.com/ceph/rpm-nautilus/el7/x86_64
enabled=1
priority=2
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://mirrors.aliyun.com/ceph/rpm-nautilus/el7/noarch
enabled=1
priority=2
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=https://mirrors.aliyun.com/ceph/rpm-nautilus/el7/SRPMS
enabled=0
priority=2
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/ceph/keys/release.asc
EOF

# 不是新内核时重启
uname -r |grep "^5" || reboot

# 允许密码登录
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

# 在 CentOS 和 RHEL 上， SELinux 默认为 Enforcing 开启状态。为简化安装，我们建议把 SELinux 设置为 Permissive 或者完全禁用，也就是在加固系统配置前先确保集群的安装、配置没问题。用下列命令把 SELinux 设置为 Permissive 
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# 确保你的包管理器安装了优先级/首选项包且已启用。在 CentOS 上你也许得安装 EPEL ，在 RHEL 上你也许得启用可选软件库。
yum install -y yum-plugin-priorities epel-release

# 解决 ceph-deploy 报错：ImportError: No module named pkg_resources
yum install -y python2-pip

# 互相ssh
su -c 'cat /dev/zero |ssh-keygen -q -N ""' vagrant
yum install -y sshpass
for node in `seq 1 3`;do
	su -c "sshpass -p vagrant ssh-copy-id vagrant@node-${node} -o StrictHostKeyChecking=no" vagrant
done

# root 互相ssh
cat /dev/zero |ssh-keygen -q -N ""
for node in `seq 1 3`;do
	sshpass -p vagrant ssh-copy-id node-${node} -o StrictHostKeyChecking=no
done