#!/bin/bash
if [ $# -lt 1 ]; then
    echo "error.. need args"
    exit 1
fi
echo "commond is $0"
echo "\$@ is $@"
echo "\$* is $*"
echo "args are:"
for arg in "$@"
do
    echo $arg
done
