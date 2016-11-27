#!/bin/bash

listfile=file_list.txt
rltfile=upload_rlt.txt

ls *.caffemodel>>$listfile

cat $listfile
list=$(cat $listfile)

for file in $list; do
qrsctl put -c facex-zfnet-end2end-250k350k $file $file && echo $file " >>>>> upload fineished" && echo $file " >>>>> upload fineished">>$rltfile
done