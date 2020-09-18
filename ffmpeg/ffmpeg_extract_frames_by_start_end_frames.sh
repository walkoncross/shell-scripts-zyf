#!/bin/bash
# author: zhaoyafei0210@gmail.com

function show_usage {
	cmd_name=$(basename $0)
    echo "Extract frames in the range between <start> and <end> "
    echo ""
    echo "Usage: "
	echo "	${cmd_name} -h"
	echo "	${cmd_name} --help"
    echo "		Show this usage"
	echo "	${cmd_name} <video> <start> <end>"
    echo "		<video>: path name for the video"
    echo "		<start>: index for the start frame, indexing from 0"
    echo "		<end>: index for the end frame, indexing from 0"
}

if [[ $# -lt 2 ]]; then
	show_usage
    exit
fi

input=$1
start=$2
end=$3

base_name=$(basename ${input})
# echo "base name: ${base_name}"

name=${base_name%%.*}
save_dir=${name}_frames_btw_${start}_${end}

fps=`ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate ${input} | bc`

echo "input: ${input}"
echo "fps: ${fps}"
echo "start frame: ${start}"
echo "end frame: ${end}"
echo "save dir: ${save_dir}"

mkdir -p ${save_dir}

ffmpeg -i ${input} -vf trim=start_frame=${start}:end_frame=${end} ${save_dir}/frame_%03d.jpg
