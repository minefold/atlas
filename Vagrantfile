Vagrant.configure("2") do |config|
  config.berkshelf.enabled = true

  config.vm.provider :virtualbox do |vb|
    config.vm.box = "quantal"
    config.vm.box_url = "https://github.com/downloads/roderik/VagrantQuantal64Box/quantal64.box"
    config.vm.network :forwarded_port, guest: 6100, host: 6100
  end

  config.vm.provision :shell, inline: "apt-get install ruby1.9.1-dev; gem install chef --version 11.4.2 --no-rdoc --no-ri --conservative"

  config.vm.provision :chef_solo do |chef|
    chef.add_recipe "apt"
    chef.add_recipe "overviewer"
    chef.add_recipe "s3cmd"
    chef.add_recipe "atlas"

    chef.json = {
      overviewer: {
        rev: 'a147ca4a361055ee196dfc9194b4a3df2bd156dc',
      },
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
