#!/bin/bash

listfile=file_list.txt
rltfile=upload_rlt.txt

ls *.gz *.bz2>>$listfile

cat $listfile
list=$(cat $listfile)

for file in $list; do
qrsctl put -c dlib-data $file $file && echo $file " >>>>> upload fineished" && echo $file " >>>>> upload fineished">>$rltfile
done