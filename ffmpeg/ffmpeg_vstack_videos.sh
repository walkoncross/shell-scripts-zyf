#!/bin/bash
## Vertically stack two videos with the same size, using ffmpeg
#! Author: zhaoyafei0210@gmail.com

out_video='output.mp4'
if [[ $# -gt 2 ]]; then
	out_video=$3
fi
echo "save into $out_video"

ffmpeg -i $1 -i $2 -filter_complex vstack $out_video

