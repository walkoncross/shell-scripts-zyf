#!/bin/bash
if [ $# -lt 1 ]; then
    echo 'usage: kill_all_proc_with_name.sh <proceed_name> [<except_pid>]'
    echo 'Please input a proceed name to kill'
    exit
fi

echo 'Kill all proceed with name contains ' $1

ex_pid=0

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
