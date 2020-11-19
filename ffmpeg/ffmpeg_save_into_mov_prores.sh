#!/bin/bash
# author: zhaoyafei0210@gmail.com
# date: 20201114

function show_usage {
	cmd_name=$(basename $0)
    echo "Save input video into ProRes encoded video with .mp4 format, with film tune settings"
    echo "Usage: "
	echo "	${cmd_name} -h"
	echo "	${cmd_name} --help"
    echo "		Show this usage"
	echo "	${cmd_name} <video> [<output_video>]"
    echo "		<video>: path name for the input video"
    echo "		<output_video>: optional, path name ended with .mp4 for the output video"
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
	show_usage
    exit
fi

input=$1
offset=$2 # time offset in seconds, e.g. 0.1 makes audio delay for 100ms, -0.1 makes audio 

if [[ $# -gt 1 ]]; then
output=$2
else
basename=${input##*/}
output=${basename%%.*}.prores.mov
fi

# ffmpeg -hide_banner -i $input -pix_fmt yuv422p10le -vcodec prores $output
ffmpeg -hide_banner -i $input -vcodec prores $output

echo 'saved into '${output}
