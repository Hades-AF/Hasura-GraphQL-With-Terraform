#! /bin/bash
sudo apt update -y
sudo apt install apache2 -y
sudo systemctl start apache2
sudo systemctl enable apache2
sudo bash -c 'echo basic web server test > /var/www/html/index.html'