Vagrant.require_version ">= 1.4.3"
VAGRANTFILE_API_VERSION = "2"

BOX='centos/7'

(1..3).each do |i|
  Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.define :"node-#{i}" do |node|
      node.vm.box = BOX
      node.vm.box_url = BOX_URL
      node.vm.network :private_network, ip: "192.168.1.#{i+100}"
      node.vm.hostname = "node-#{i}"
      node.vm.synced_folder ".", "/vagrant"
      node.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
      node.vm.provision "shell", path: "post-deploy.sh" ,run: "always"
      node.vm.provider "virtualbox" do |v|
        v.customize ["modifyvm", :id, "--memory", "2048"]
        v.name = "node-#{i}"
        v.gui = false

        (1..3).each do |k|
          node_disk = "./node-#{i}/node_disk#{i}.vdi"
          unless File.exists?(node_disk)
          v.customize ['createhd', '--filename', node_disk, '--size', 1 * 5120]
          v.customize ['storageattach', :id,  '--storagectl', 'IDE', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', node_disk]
          end
        end
      end
    end
  end
end
