bkt=$1
file=$2

#echo on
echo "bucket: " $bkt
echo "file: " $file
qrsctl login pulp@qiniu.com Bob_dylon456
qrsctl put -c $bkt $file $file
