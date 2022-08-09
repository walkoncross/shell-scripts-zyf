#/bin/sh
echo "===================================" 
echo "—> list dangling images: "
echo "—----------------------------------" 
sudo docker images --filter "dangling=true"