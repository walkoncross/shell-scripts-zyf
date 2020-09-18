#!/bin/bash
# author: zhaoyafei0210@gmail.com

function show_usage {
	cmd_name=$(basename $0)
    echo "Extract frames, <fps> frame per second, starting from the first frame (frame #0)"
    echo ""
    echo "Usage: "
	echo "	${cmd_name} -h"
	echo "	${cmd_name} --help"
    echo "		Show this usage"
	echo "	${cmd_name} <video> [<frame_idx>...]"
    echo "		<video>: path name for the video"
    echo "		<frame_idx>: frame idx list, e.g. 1 or '1 2 3', default 0"
}

if [[ $# -lt 1 ]]; then
	show_usage
    exit
fi

input=$1
frames=0

if [[ $# -gt 1 ]]; then
frames=${@:2}
fi 

base_name=$(basename ${input})
# echo "base name: ${base_name}"

name=${base_name%%.*}
save_dir=${name}_${fps}_frames_by_index

fps=`ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate ${input} | bc`

echo "input: ${input}"
echo "fps: ${fps}"
echo "frames: ${frames}"
echo "save dir: ${save_dir}"

mkdir -p ${save_dir}

time for i in ${frames} ; do ffmpeg -accurate_seek -ss `echo $i/${fps} | bc` -i ${input} -frames:v 1 ${save_dir}/frame_$i.jpg; done
