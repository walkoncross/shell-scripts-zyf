#!/bin/bash
# author: zhaoyafei0210@gmail.com
# date: 20200914

function show_usage {
	cmd_name=$(basename $0)
    echo "Usage: "
	echo "	${cmd_name} -h"
	echo "	${cmd_name} --help"
    echo "		Show this usage"
	echo "	${cmd_name} <video> <offset> [<output_video>]"
    echo "		<video>: path name for the input video"
    echo "		<offset>: time offset in seconds"
    echo "              e.g. 0.1 makes audio delay for 100ms when audio happens before video in original video file,"
    echo "                  -0.1 makes audio advance for 100 ms when audio happens after video  in original video file"
    echo "		<output_video>: optional, path name ended with .mp4 for the output video"
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
	show_usage
    exit
fi

input=$1
offset=$2 # time offset in seconds, e.g. 0.1 makes audio delay for 100ms, -0.1 makes audio 

if [[ $# -gt 2 ]]; then
output=$3
else
output=${input%%.*}_offset_$offset.mp4
fi

ffmpeg -i $input -itsoffset $offset -i $input -vcodec copy -acodec copy -map 0:0 -map 1:1 $output
