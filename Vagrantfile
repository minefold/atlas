Vagrant.configure("2") do |config|
  config.vm.provider :aws do |aws|
    aws.access_key_id = ENV['AWS_ACCESS_KEY']
    aws.secret_access_key = ENV['AWS_SECRET_KEY']
    aws.region = "us-east-1"
    aws.region_config "us-east-1", :ami => "ami-bef924d7"
  end

  config.vm.provider :virtualbox do |vb|
    config.vm.box = "quantal"
    config.vm.box_url = "https://github.com/downloads/roderik/VagrantQuantal64Box/quantal64.box"
    config.vm.network :forwarded_port, guest: 6100, host: 6100
  end

  config.berkshelf.enabled = true

  config.vm.provision :chef_solo do |chef|
    chef.add_recipe "apt"
    chef.add_recipe "overviewer"
    chef.add_recipe "s3cmd"
    chef.add_recipe "atlas"

    chef.json = {
      atlas: {
        user: 'vagrant'
      },
      s3cmd: {
        users: ['vagrant'],
        aws_access_key_id: ENV['AWS_ACCESS_KEY'],
        aws_secret_access_key: ENV['AWS_SECRET_KEY'],
      }
    }
  end
end
