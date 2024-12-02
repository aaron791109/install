#!/bin/bash

if command -v apt-get >/dev/null; then
    echo "apt-get is used here"

    # Debian/Ubuntu 系统使用 apt-get
    sudo apt update -y
    sudo apt install -y software-properties-common

    sudo add-apt-repository ppa:ondrej/nginx-mainline -y
    sudo apt update -y
    sudo apt install -y nginx-full

    sudo systemctl start nginx
    sudo systemctl enable nginx

elif command -v yum >/dev/null; then
    echo "yum is used here"

    # CentOS/RHEL/Fedora 系统使用 yum
    sudo curl -o /etc/yum.repos.d/nginx.repo https://nginx.org/packages/centos/nginx.repo

    sudo yum update -y
    sudo yum install -y nginx

    sudo systemctl start nginx
    sudo systemctl enable nginx
else
    echo "Not support Linux OS"
fi
