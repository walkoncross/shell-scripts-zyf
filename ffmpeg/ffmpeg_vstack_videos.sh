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
	echo "	${cmd_name} <video1> <video2> [<output_video>]"
    echo "		<video1>: path name for the first video"
    echo "		<video2>: path name for the second video"
    echo "		<output_video>: optional, path name ended with .mp4 for the output video"
}

if [[ $# -lt 1 || $# -gt 3 || $1 == '-h' || $1 == '--help' ]]; then
	show_usage
    exit
fi

if [[ $# -eq 2 ]]; then
	basename1=$(basename $1)
	basename2=$(basename $2)
	output_video=${basename1%%.*}'_and_'${basename2%%.*}'_hstack.mp4'
else
	output_video=${3%%.*}'.mp4'
fi

echo "===> The output video will be saved into: ${output_video}"

ffmpeg -i $1 -i $2 -filter_complex hstack ${output_video}
