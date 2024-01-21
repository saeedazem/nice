#!/bin/bash
apt update
apt upgrade -y
apt install apache2 -y
echo "<h1>Hello world from highly available group of ec2 instances</h1>" > /var/www/html/index.html
systemctl start apache2
systemctl enable apache2
#install the CodeDeploy agent 
sudo apt update
sudo apt install ruby-full -y
sudo apt install wget
cd /home/ubuntu
wget https://aws-codedeploy-eu-west-1.s3.eu-west-1.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto > /tmp/logfile
