#!/bin/bash
# author: zhaoyafei0210@gmail.com

input=$1
output=${input%%.*}'.webp'

if [[ $# -gt 1 ]]; then
if [[ -d $2 ]]; then
        base=`basename $output`
        output="$2/$base"
else
        output=$2
fi
fi

echo "==>input: $input"
echo "==>output: $output"

cwebp $input -o $output
