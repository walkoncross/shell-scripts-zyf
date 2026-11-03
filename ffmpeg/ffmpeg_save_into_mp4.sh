#!/bin/bash
# author: zhaoyafei0210@gmail.com
# date: 20201114

function show_usage {
	cmd_name=$(basename $0)
    echo "Save input video into h264 encoded video with .mp4 format, with film tune settings"
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
output=${basename%%.*}.x264.mp4
fi

# Reference: https://trac.ffmpeg.org/wiki/Encode/H.264
# -preset:
    # ultrafast
    # superfast
    # veryfast
    # faster
    # fast
    # medium – default preset
    # slow
    # slower
    # veryslow
    # placebo – ignore this as it is not useful (see FAQ)
# -tune:
    # film – use for high quality movie content; lowers deblocking
    # animation – good for cartoons; uses higher deblocking and more reference frames
    # grain – preserves the grain structure in old, grainy film material
    # stillimage – good for slideshow-like content
    # fastdecode – allows faster decoding by disabling certain filters
    # zerolatency – good for fast encoding and low-latency streaming
    # psnr – ignore this as it is only used for codec development
    # ssim – ignore this as it is only used for codec development

# ffmpeg -hide_banner -i $input -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2"  -pix_fmt yuv420p -vcodec libx264 -preset fast -tune film $output
# ffmpeg -hide_banner -i $input -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2"  -pix_fmt yuv420p -vcodec libx264 -tune film $output
ffmpeg -hide_banner -i $input -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2"  -pix_fmt yuv420p -vcodec libx264 $output

echo 'saved into '${output}
