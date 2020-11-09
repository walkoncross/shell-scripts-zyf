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

if [[ $# -lt 2 || $# -gt 3 ]]; then
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

resolution1=`ffprobe -v error \
	-select_streams v:0 \
	-show_entries stream=width,height \
	-of csv=s=x:p=0 \
	$1`

echo "---> resolution ($1): $resolution1"

resolution2=`ffprobe -v error \
	-select_streams v:0 \
	-show_entries stream=width,height \
	-of csv=s=x:p=0 \
	$2`

echo "---> resolution ($2): $resolution2"

ht1=${resolution1##*x}
ht2=${resolution2##*x}

if [[ $ht1 == $ht2 ]]; then
	echo "---> The two videos have the same height, just stack them"
	ffmpeg -i $1 -i $2 -filter_complex '[0:v] crop=h=(ih/2)*2:w=(iw/2)*2 [v0_crop]; [1:v] crop=h=(ih/2)*2:w=(iw/2)*2 [v1_crop]; [v0_crop][v1_crop] hstack' ${output_video}
else
	echo "---> The two videos have the different height, resize the second one and then stack them"
	# #w=-2, refer to: https://stackoverflow.com/questions/20847674/ffmpeg-libx264-height-not-divisible-by-2
	ffmpeg -i $1 -i $2 	\
		-filter_complex '[0:v] crop=h=(ih/2)*2:w=(iw/2)*2 [v0_crop]; [1:v] crop=h=(ih/2)*2:w=(iw/2)*2 [v1_crop]; [v1_crop][v0_crop] scale2ref=w=-2:h=ih [rightvid][leftvid]; [leftvid][rightvid] hstack [outvid]' \
		-map '[outvid]' \
		-map 0:a \
		-vf "pad=ceil(iw/2)*2:ceil(ih/2)*2"
		${output_video}
fi

# ffmpeg -i 0.mp4 -i 0_1.mp4 \
# 	-filter_complex '[1:v][0:v] scale2ref=w=-2:h=ih [rightvid][leftvid]; [leftvid]][rightvid] hstack [outvid]' \
# 	-map '[outvid]' \
# 	-map 0:a \
# 	0_and_0_1_hstack.mp4
