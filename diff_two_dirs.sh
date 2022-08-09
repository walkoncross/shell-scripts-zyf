
dir1=$1
dir2=$2

if [[ ! -d $dir1 ]]; 
then
    echo 'dir1 does not exists: ' $dir1
    exit -1
fi

if [[ ! -d $dir2 ]]; 
then
    echo 'dir2 does not exists: ' $dir2
    exit -1
fi

for ff1 in $dir1/*.*
do
    bn=$(basename $ff1)
    echo '=================='
    echo 'file1: ' $ff1

    ff2=$dir2/$bn

    if [[ -e $ff2 ]]
    then
        echo 'file2 exists: ' $ff2
        echo 'DIFF:'
        diff $ff1 $ff2
    else
        echo 'file2 does not exist: ' $ff2
    fi
done