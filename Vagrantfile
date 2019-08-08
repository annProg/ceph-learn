Vagrant.require_version ">= 1.4.3"
VAGRANTFILE_API_VERSION = "2"

BOX='centos-sata/7'

(1..3).each do |i|
  Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.define :"ceph#{i}" do |node|
      node.vm.box = BOX
      #node.vm.box_url = BOX_URL
      node.vm.network :private_network, ip: "192.168.1.#{i+100}"
      node.vm.hostname = "ceph#{i}"
      node.vm.synced_folder ".", "/vagrant", disabled: true
      if Vagrant.has_plugin?("vagrant-vbguest")
        node.vbguest.auto_update = false
      end      
      node.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
      node.vm.provision "shell", path: "post-deploy.sh" ,run: "always"
      #node.vm.provision "puppet",run: "always" do |puppet|
      #  puppet.module_path = "./manifests/ceph"
      #end
      node.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", "1024"]
        v.name = "ceph#{i}"
        v.gui = false

        (1..3).each do |k|
          node_disk = "./ceph#{i}/node_disk#{k}.vdi"
          unless File.exists?(node_disk)
            v.customize ['createhd', '--filename', node_disk, '--size', 1 * 5120]
          end
          v.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', "#{k}", '--device', 0, '--type', 'hdd', '--medium', node_disk]
        end
      end
    end
  end
end
