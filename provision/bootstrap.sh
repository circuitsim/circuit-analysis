#!/usr/bin/env bash

VAGRANT_HOME=/home/vagrant

apt-get update -y > /dev/null

echo "--- Install NVM ---"
apt-get install -y curl > /dev/null
sudo su vagrant -c "curl -silent https://raw.githubusercontent.com/creationix/nvm/v0.23.3/install.sh | bash"

echo "--- Load up NVM ---"
source /home/vagrant/.profile &> /dev/null
source /home/vagrant/.nvm/nvm.sh &> /dev/null

sudo su -l vagrant

echo "--- Install NodeJS v0.10.* ---"
nvm install 0.10 &> /dev/null
nvm alias default 0.10

npm install -g coffee-script

echo "--- Ensure 'vagrant ssh' opens /vagrant dir ---"
if ! grep -q "cd /vagrant" $VAGRANT_HOME/.bashrc; then
  echo "cd /vagrant" >> $VAGRANT_HOME/.bashrc
fi
