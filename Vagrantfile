Vagrant.configure("2") do |config|
  project_home     = File.expand_path(File.join(File.dirname(__FILE__)))
  states           = project_home
  pillar           = File.join(project_home, "pillar")
  dev_formulas     = File.join(project_home, '..', 'formulas')
  dot_m2_folder    = File.join(Dir.home, '.m2', 'repository')
  m2_folder        = dot_m2_folder if FileTest.directory?(dot_m2_folder)
  Dir.mkdir(pillar) unless FileTest.directory?(pillar)
  clusterdomain    = "hadoop.local"
  datanode_count   = ENV['NODE_COUNT'] || '0'
  vmname_prefix    = ENV['VMNAME_PREFIX'] || 'hadoop-salt'
  os               = ENV['VIRT_OS'] || 'centos'
  is_singlenode    = datanode_count.eql?('0')
  baseboxes        = { 'centos' => 'centos6min-salt-0.17.4', 'ubuntu' => 'ubuntu-salt-0.17.4' }
  node_list        = "1".upto(datanode_count).collect {|c| "dnode#{c}"} + ["namenode"]

  config.vm.synced_folder m2_folder, "/mavenrepo" unless m2_folder.nil?
  config.vm.synced_folder states, "/srv/salt"
  config.vm.synced_folder pillar, "/srv/pillar"

  box = baseboxes[os] || baseboxes['centos']
  config.vm.box_url = "http://sroegner-vagrant.s3.amazonaws.com/#{box}.box"
  config.vm.box = "#{box}"

  node_list.each do |nodename|
    fqdn = "#{nodename}.#{clusterdomain}"
    ip = nodename.eql?('namenode') ? '192.169.10.111' : "192.169.10.10#{node_list.index(nodename)}"
    config.vm.define nodename do |n|
      n.vm.network :private_network, ip:"#{ip}", :adapter => 2
      n.vm.provider "virtualbox" do |v, override|
        override.vm.provision :shell, :path => 'vagrant-bootstrap/bs.sh', :args => "#{datanode_count} #{os} #{fqdn}"
        if nodename.eql?("namenode")
          if is_singlenode
            v.customize [ 'modifyvm', :id, '--name', "#{vmname_prefix}-#{nodename}", '--memory', "6144", '--cpus', "2" ]
          else
            v.customize [ 'modifyvm', :id, '--name', "#{vmname_prefix}-#{nodename}", '--memory', "3072", '--cpus', "2" ]
          end
        else
          v.customize [ 'modifyvm', :id, '--name', "#{vmname_prefix}-#{nodename}", '--memory', "2048", '--cpus', "1" ]
        end
      end
    end
  end

end


