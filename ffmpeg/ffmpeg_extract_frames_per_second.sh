#!/bin/bash
# author: zhaoyafei0210@gmail.com

function show_usage {
	cmd_name=$(basename $0)
    echo "Extract frames, <ex_fps> frame per second, starting from the first frame (frame #0)"
    echo ""
    echo "Usage: "
	echo "	${cmd_name} -h"
	echo "	${cmd_name} --help"
    echo "		Show this usage"
	echo "	${cmd_name} <video> [<ex_fps>]"
    echo "		<video>: path name for the video"
    echo "		<ex_fps>: frames to extract per second, must <= the real framerate of the video"
    echo "		        may be: 1 for 1 frame per 1 seconds"
    echo "		        may be: 0.5 for 1 frame per 2 seconds"
}

if [[ $# -le 1 ]] || [[ $# -gt 2 ]]; then
	show_usage
    exit
fi

input=$1
ex_fps=1

if [[ $# -eq 2 ]]; then
ex_fps=$2
fi 

base_name=$(basename ${input})
# echo "base name: ${base_name}"

name=${base_name%%.*}
save_dir=${name}_${ex_fps}_frames_per_second

fps=`ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate ${input} | bc`

echo "input: ${input}"
echo "fps: ${fps}"
echo "ex_fps: ${ex_fps}"
echo "save dir: ${save_dir}"

mkdir -p ${save_dir}

# time ffmpeg -i ${input} -filter:v ex_fps=ex_fps=${ex_fps}:start_time=0 ${save_dir}/frame_%0d.jpg
# time for i in {0..5} ; do ffmpeg -accurate_seek -ss `echo $i/${fps} | bc` -i ${input} -frames:v 1 ${name}_frame_$i.jpg; done
# time ffmpeg -accurate_seek -ss 0 -i ${input} -frames:v 1  ${save_dir}/frame_0.jpg
time ffmpeg -i ${input} -r ${ex_fps} -f image2 ${save_dir}/frame_%0d.jpg

