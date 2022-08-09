#/bin/sh
im=$1
sudo docker ps -a -f "ancestor=$im"
