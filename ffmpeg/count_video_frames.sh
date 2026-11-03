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

ffprobe -v quiet \
	-show_streams -show_entries stream=nb_frames,nb_read_packets \
	-count_frames -count_packets \
	-pretty \
	$1
	# -select_streams v \
