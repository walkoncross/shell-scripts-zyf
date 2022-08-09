#/bin/sh
for im in $(sudo docker images --filter "dangling=true" -q); do
    echo "===================================" 
    echo "—> dangling image: " $im 
    echo "—----------------------------------" 
    echo "-> containers using this image"
    echo "—----------------------------------" 
    sudo docker ps -a -f "ancestor=$im" -f "status=exited"
done

echo 'Are you sure to remove all dangling iamge [y/n]: '
read ans

echo "ans:" "${ans}"

if [[ "${ans}" == "y" ]]; then
    echo "===================================" 
    echo "—> rm containers using all exited containers using dangling images: "
    echo "—----------------------------------" 

    for im in $(sudo docker images --filter "dangling=true" -q); do
        echo "===================================" 
        echo "—> dangling image: " $im 
        echo "—----------------------------------" 
        echo "-> removing containers using this image"
        sudo docker rm $(sudo docker ps -a -f "ancestor=$im" -f "status=exited" -q)
        echo "—----------------------------------" 
        echo "—> remove dangling image: " $im 
        sudo docker rmi $im
    done
else
    echo "---> No containers deleted"
fi
