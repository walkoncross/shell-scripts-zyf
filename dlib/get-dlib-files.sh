#!/bin/bash

listfile=dlib-files.txt
rltfile=upload_rlt.txt

cat $listfile
list=$(cat $listfile)

for file in $list; do
wget $file && echo $file " >>>>> download finished" && echo $file " >>>>> download finished">>$rltfile
done