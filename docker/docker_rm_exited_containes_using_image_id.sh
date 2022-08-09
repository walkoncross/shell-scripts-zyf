#/bin/sh
im=$1

echo "===================================" 
echo "—> image id: " $im 
echo "—----------------------------------" 
echo "-> containers using this image"

sudo docker ps -a -f "ancestor=$im" -f 'status=exited'
