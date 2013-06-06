package 'ruby1.9.1-dev'
package 'curl'
package 'lzop'

chef_gem 'bundler'

bash "install toolbelt" do
  code 'curl https://toolbelt.heroku.com/install-ubuntu.sh | sh'
  not_if "which heroku"
end

bash "install partycloud tools" do
  code 'curl http://party-cloud-production.s3.amazonaws.com/pc-tools/install.sh | sh'
  not_if "which restore-dir"
end

bash "install minecraft client" do
  code 'wget -N http://s3.amazonaws.com/MinecraftDownload/minecraft.jar -P /home/vagrant/.minecraft/bin/'
  not_if { ::File.exists?('/home/vagrant/.minecraft/bin/minecraft.jar') }
end

easy_install_package "boto"

git "/usr/local/s3-parallel-put" do
  repository "https://github.com/twpayne/s3-parallel-put"
end
link "/usr/local/bin/s3-parallel-put" do
  to "/usr/local/s3-parallel-put/s3-parallel-put"
end