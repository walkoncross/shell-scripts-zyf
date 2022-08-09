#!/bin/bash
## author: zhaoyafei0210@gmail.com


input=$1
#max_size=$2
max_size=1000
output="${input%.*}.jpg"

if [[ $# -gt 1 ]]; then
if [[ -d $3 ]]; then
        base=`basename $output`
        output="$3/$base"
else
        output=$3
fi
fi

echo "==> save ${input} into ${output}"

sips -Z ${max_size} -s format jpeg $input 1 --out $output
