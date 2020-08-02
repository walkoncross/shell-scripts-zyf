#!/bin/bash
## Author: zhaoyafei0210@gmail.com

function show_usage {
	cmd_name=$(basename $0)
    echo "Usage: "
	echo "	${cmd_name} -h"
	echo "	${cmd_name} --help"
    echo "		Show this usage"
	echo "	${cmd_name} <video>"
    echo "		<video>: path name for the video"
}

if [[ $# -lt 1 || $# -gt 1 || $1 == '-h' || $1 == '--help' ]]; then
	show_usage
    exit
fi

ffprobe -v error \
	-select_streams v:0 \
	-show_entries stream=width,height \
	-of compact \
	$1

# ffprobe -v error \
# 	-select_streams v:0 \
# 	-show_entries stream=width,height \
# 	-of csv=s=x:p=0 \
# 	$1

# ffprobe -v error \
# 	-select_streams v:0 \
# 	-show_entries stream=width,height \
# 	-of json \
# 	$1		