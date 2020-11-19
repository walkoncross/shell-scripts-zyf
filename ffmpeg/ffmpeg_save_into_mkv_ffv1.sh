#!/bin/bash
# author: zhaoyafei0210@gmail.com
# date: 20201114

function show_usage {
	cmd_name=$(basename $0)
    echo "Save input video into ffv1 encoded video with .mp4 format, with film tune settings"
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
output=${basename%%.*}.ffv1.mkv
fi

# Reference: 
#   https://trac.ffmpeg.org/wiki/Encode/FFV1

# FFV1 version 1
# ffmpeg -hide_banner     \
#     -i       $input     \
#     -pix_fmt yuv420p    \
#     -acodec  copy       \
#     -vcodec  ffv1       \
#     -level   1          \
#     -coder   1          \
#     -context 1          \
#     -g       1          \
#     $output

# FFV1 version 3
ffmpeg -hide_banner     \
    -i        $input    \
    -pix_fmt  yuv420p   \
    -acodec   copy      \
    -vcodec   ffv1      \
    -level    3         \
    -coder    1         \
    -context  1         \
    -threads  8         \
    -g        1         \
    -slices   24        \
    -slicecrc 1         \
    $output

echo 'saved into '${output}
