#!/bin/bash
## Author: zhaoyafei0210@gmail.com

function show_usage {
    cmd_name=$(basename $0)
    echo "Usage: "
    echo "$cmd_name <proceed_name> [<except_pid>]"
    echo "Kill all proceed with name contains <proceed_name> except the one with <except_pid>"
    echo "  <proceed_name>: proceed name (e.g. vi, python), proceeds with this name will be killed"
    echo "  <except_pid>: (optional) proceed pid to be an exception"
}


if [ $# -lt 1 ]; then
    show_usage
    echo 'Please input a proceed name to kill'
    exit
fi

echo 'Kill all proceed with name contains ' $1

ex_pid=1

if [ $# -gt 1 ]; then
    ex_pid=$2
    echo 'But except the one with pid ', $2
fi

#awk_cmd='{ print $1; {cmd="kill -9 "$1; print cmd; system(cmd);} }'
#echo 'awk action: ' ${awk_cmd}

ps -ax \
    | grep $1 \
    | awk '{ print $1; if($1!=$ex_pid){cmd="kill -9 "$1; print cmd; system(cmd);} }'
#    | awk ${awk_cmd}
