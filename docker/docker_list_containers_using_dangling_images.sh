#/bin/sh
for im in $(sudo docker images --filter "dangling=true" -q); do
    echo "===================================" 
    echo "—> dangling image: " $im 
    echo "—----------------------------------" 
    echo "-> containers using this image"
    echo "—----------------------------------" 
    sudo docker ps -a -f "ancestor=$im" -f "status=exited"
done