#/bin/sh
echo "===================================" 
echo "—> list dangling images: "
echo "—----------------------------------" 
sudo docker images --filter "dangling=true"

echo 'Are you sure to remove all dangling iamge [y/n]: '
read ans

echo "ans:" "${ans}"

if [[ "${ans}" == "y" ]]; then
    echo "===================================" 
    echo "—> rm dangling images: "
    echo "—----------------------------------" 
    sudo docker rmi $(sudo docker images --filter "dangling=true" -q)
else
    echo "---> No images deleted"
fi
