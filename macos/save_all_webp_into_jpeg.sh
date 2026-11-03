#!/bin/bash
## author: zhaoyafei0210@gmail.com


dir=$1

for input in `ls ${dir}/*.WEBP ${dir}/*.webp`; do

echo ${input}
output="${input%.*}.jpeg"

if [[ $# -gt 1 ]]; then
if [[ -d $2 ]]; then
        base=`basename $output`
        output="$2/$base"
else
        output=$2
fi
fi

echo "==> save ${input} into ${output}"

sips -s format jpeg $input --out $output

done
