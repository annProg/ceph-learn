# ceph-learn
learn ceph

## 自制支持SATA控制器的box
主机名改为vagrant，删除共享文件夹

vagrant up时会替换 insecure public key，自制box时需要需要先恢复 `vagrant insecure public key`，否则会报错
```
  node-1: SSH auth method: private key
    node-1: Warning: Authentication failure. Retrying...
    node-1: Warning: Authentication failure. Retrying...
    node-1: Warning: Authentication failure. Retrying...
    node-1: Warning: Authentication failure. Retrying...
```
参加：https://blog.csdn.net/qq_27068845/article/details/80936081

基于centos/7，在virtualbox 图形界面添加SATA控制器之后关机。执行以下命令导出box

```
 vagrant.exe package --base node-1
```
Vagrant将创建名为package.box的新的box，此后我们便可以使用该package.box作为其他虚拟机的基础box了。另外，如果当前处于Vagrantfile文件所在目录，则可简化创建命令：

```
vagrant package
```

add box

```
vagrant.exe box add package.box --name=centos-sata/7
```

## 管理硬盘
直接删除硬盘文件，会报错：VERR_ALREADY_EXISTS，需通过VBOXmanage删除

```
VBoxManage.exe list hdds
VBoxManage.exe closemedium disk /e/dev/ceph-learn/node-2/node_disk1.vdi --delete
```