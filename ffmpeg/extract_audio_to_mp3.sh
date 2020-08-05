#!/bin/bash
## Author: zhaoyafei0210@gmail.com

## Horizontally stack two videos with the same size, using ffmpeg
# Stream mapping  (example):
#   Stream #0:0 (h264) -> hstack:input0 (graph 0)
#   Stream #1:0 (h264) -> hstack:input1 (graph 0)
#   hstack (graph 0) -> Stream #0:0 (libx264)
#   Stream #0:1 -> #0:1 (aac (native) -> aac (native))

function show_usage {
	cmd_name=$(basename $0)
    echo "Usage: "
	echo "	${cmd_name} -h"
	echo "	${cmd_name} --help"
    echo "		Show this usage"
	echo "	${cmd_name} <video>"
    echo "		<video>: path name for the first video"
}

if [[ $# -lt 1 ]]; then
	show_usage
    exit
fi

basename=$(basename $1)
output_audio=${basename%%.*}'.mp3'

echo "===> The output audio will be saved into: ${output_audio}"
ffmpeg -i $1 -vn ${output_audio}
