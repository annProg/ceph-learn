# ceph-learn
learn ceph

## 自制支持 SATA 控制器的 box

基于 centos/7 启动一个 vm

```
vagrant init centos/7
vagrant up
```

修复 keypair

制作 box 时禁止 insert_key，添加 config.ssh.insert_key = false，否则会报 `Authentication failure. Retrying...`

```
Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.ssh.insert_key = false
end
```

参见：

- https://github.com/hashicorp/vagrant/issues/5186#issuecomment-71769017
- https://blog.csdn.net/qq_27068845/article/details/80936081
- https://www.vagrantup.com/docs/boxes/base.html#quot-vagrant-quot-user

关机，在 virtualbox 图形界面添加 SATA 控制器。执行以下命令导出 box

```
 vagrant.exe package
```
Vagrant 将创建名为 package.box 的新的 box，此后我们便可以使用该 package.box 作为其他虚拟机的基础 box 了。另外，如果当前处于 Vagrantfile 文件所在目录，则可简化创建命令：

```
vagrant package
```

add box

```
vagrant.exe box add package.box --name=centos-sata/7
```

安装 vagrant-vbguest

```
vagrant.exe plugin install vagrant-vbguest
```

解决如下报错

```
Vagrant was unable to mount VirtualBox shared folders. This is usually
because the filesystem "vboxsf" is not available. This filesystem is
made available via the VirtualBox Guest Additions and kernel module.
Please verify that these guest additions are properly installed in the
guest. This is not a bug in Vagrant and is usually caused by a faulty
Vagrant box. For context, the command attempted was:
```

## 管理硬盘
直接删除硬盘文件，会报错：VERR_ALREADY_EXISTS，需通过 VBOXmanage 删除

```
VBoxManage.exe list hdds
VBoxManage.exe closemedium disk /e/dev/ceph-learn/node-2/node_disk1.vdi --delete
```

## ceph-deploy

指定国内 repo

```
ceph-deploy install --repo-url https://mirrors.aliyun.com/ceph/rpm-nautilus/el7 --gpg-url https://mirrors.aliyun.com/ceph/keys/release.asc node-1
```

重新创建 osd

```
# lvremove 
# vgremove ceph ...
```