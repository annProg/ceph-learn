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

[ ! -d /root/.ssh ] && mkdir /root/.ssh
cat > /root/.ssh/id_rsa <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA1CCKeBjXeh6vTnoT1Z1zQcTTSm7sCTFtBBJbXzOR4B6z6GQd
rwCpwyxinJHrJP6/vGgFvreTZpaZbzgdz/VvycGsQ8P5awxmqUfQKAB5lO5v8xGM
XUnorsZ0aicXiNE8PJ5sjlUPRnd57jfEsnTbnIiUeASrLbz+IBa6nZvGGz7nXAut
h1E14xfkgwhuBN8YcUUix0ZLN9iKY5vKHxZgnZ+1Qsp6i3YRe1RD0VN85WlyEb8t
DWRf2GoW15LzmMiXVYWpA9S62I0slQYwQo46uDuk2F1mlef1L57fcbO+7RevVw4r
I60JMBzg1O/xpOK/Ihpse9IAmMBg06FR9fHVzwIDAQABAoIBAQCXDlksrpv7BZDW
9I3dR1MFGbFQxu5kmYLFLIFOqP2POK3qpiiRL4q0Ro4uaqalYJePBhBZQIbBviqj
DbYFGgUyCi2u0AZ0GY+dqlrrsXLjAGxODkgDQpdkpkPON+pFbqJTlIk/Tgkjp/73
CVWTsy2UKZp4YPK5DmV02lqn037edMAC519z1AVg+LK08XHSqpQ47bCPotklRNds
NNAVD1hQos8rktSNn5+a8lyuE1PkdxLUInQEZw2zq8l9Ge7Ms6bkmpbqIhs9MqU+
2DTl72P9SS79gS3SD8dlADupPlFo7jcEBDPg3sH1ZJrgVayrknmnyu7UnTXkp7vM
a1xkhFjxAoGBAOzSgPowmT6uqayaQCW74bGHnMuYcWfdEgsxqvF4unbuL1B+VF2x
nC6p/iY7I2iKU8Xyhy7BINMK6UbteBcGV1xaYGaqVlrL361JPBPH0TUxmpfpMlku
ILfpe11u5Op8XPJuaf/an5hGyxd2WdA3gRUbuE6Kzr7pAJJrNIqz1HcXAoGBAOVO
FqdzYKAVyHBu6VgqNA893AyS3KEW/1J9DTiMCDVcz6kK58gCu66SPjex6UM9saCV
vbdxeglL24vDlBAdgE/lRyafSOgUzsqbw8WAZGvR9a8RsU6Fj5kYkVVtnXOqM9RN
ig2w5jzQuwuUPfO82ShhbWh2sVLCCMVnzHene0oJAoGABPNZkuFVMsQ/88W9tYw5
6ZYmJvNm2375k5ZUNnwJmdbc0lfxt4uw8iDHmVD/Kn5JxgeN3+JVp1PBEKSCMCkH
xnx1K3BAIeHFKUAwq1EwBGanDqnnTYnzUSTmWUuqKWS0JLU+LgUJ9Qr1z+W/duTS
I/jSX4HzVHZWdrka/hNIS70CgYEAtdGGOv5MRoMfLK91DLhiERfOrJWipYSzrLeF
TSoTtCREcFg6UqiAIrrI5KaIPA3mE1vIU3WB+28PxTGt7F1ICZHWKfSw/XzKP3Lk
92yHs8qGkWto+McEhrMpQeCpsTXq5NMavSJgXSZwuYyw1twOIGuoMeWzUtiR1d0p
DlNZeekCgYBiIcwfdh/fWgs4nV1CB/lEFuAdUkeaNV8crxxb7BA47PNWkJG1HMMi
46Nbz1rD+GI6CYNyu48IBkNqZ9EnX48/cCRzlzL3ltfMajONfv0DDGbzqIyzo6n6
pjgYKILtOo/cNxgbp45bICuzNyqPeZktjtZWcSz6t5e6YQD5j9m2Dw==
-----END RSA PRIVATE KEY-----
EOF

chmod 600 /root/.ssh/id_rsa
cat >/root/.ssh/id_rsa.pub <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUIIp4GNd6Hq9OehPVnXNBxNNKbuwJMW0EEltfM5HgHrPoZB2vAKnDLGKckesk/r+8aAW+t5NmlplvOB3P9W/JwaxDw/lrDGapR9AoAHmU7m/zEYxdSeiuxnRqJxeI0Tw8nmyOVQ9Gd3nuN8SydNuciJR4BKstvP4gFrqdm8YbPudcC62HUTXjF+SDCG4E3xhxRSLHRks32Ipjm8ofFmCdn7VCynqLdhF7VEPRU3zlaXIRvy0NZF/YahbXkvOYyJdVhakD1LrYjSyVBjBCjjq4O6TYXWaV5/Uvnt9xs77tF69XDisjrQkwHODU7/Gk4r8iGmx70gCYwGDToVH18dXP user@DESKTOP-F7JI47V
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