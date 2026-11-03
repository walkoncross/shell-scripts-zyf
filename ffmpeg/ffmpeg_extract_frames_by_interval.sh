#!/bin/bash
# author: zhaoyafei0210@gmail.com

function show_usage {
	cmd_name=$(basename $0)
    echo "Extract frames, one frame per interval, starting from the first frame (frame #0)"
    echo ""
    echo "Usage: "
	echo "	${cmd_name} -h"
	echo "	${cmd_name} --help"
    echo "		Show this usage"
	echo "	${cmd_name} <video> <interval>"
    echo "		<video>: path name for the video"
    echo "		<interval>: frame per second for the video, you can your `ffprobe <video>` to checn the fps"
}

if [[ $# -lt 2 ]]; then
	show_usage
    exit
fi

input=$1
interval=$2

base_name=$(basename ${input})
# echo "base name: ${base_name}"

name=${base_name%%.*}
save_dir=${name}_frames_per_${interval}_frames

fps=`ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate ${input} | bc`

echo "input: ${input}"
echo "fps: ${fps}"
echo "interval frames: ${interval}"
echo "save dir: ${save_dir}"

mkdir -p ${save_dir}

# time ffmpeg -hide_banner -i ${input} -filter:v fps=fps=${fps}:start_time=0 ${name}_frame_%0d.jpg

#time for i in {0..5} ; do ffmpeg -accurate_seek -ss `echo $i/${fps} | bc` -i ${input} -frames:v 1 ${name}_frame_$i.jpg; done
time ffmpeg -accurate_seek -ss 0 -i ${input} -frames:v 1 ${name}_frame_0.jpg

