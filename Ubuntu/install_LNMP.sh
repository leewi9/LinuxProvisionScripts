#!/bin/bash

#
sudo LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
sudo apt-add-repository -y ppa:nginx/stable

#
sudo apt-get -y update && sudo apt-get -y upgrade

#
sudo apt-get install -y nginx

# 安装 php5.6
echo "----> start installing php5.6 ..."
sudo apt-get -y install php5.6 php5.6-cli php5.6-fpm php5.6-mysql php5.6-gd php5.6-curl php5.6-mbstring php5.6-dom php5-xdebug php5.6-zip php5.6-bz2 php5.6-json php5.6-opcache php5.6-readline


# 安装 composer
echo "----> start installing composer ..."
sudo curl -sS https://getcomposer.org/installer | sudo php
sudo mv composer.phar /usr/bin/composer
sudo rm -f composer.phar 

# 安装 mysql 见笔记
