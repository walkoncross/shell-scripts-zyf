#!/bin/bash
## Author: zhaoyafei0210@gmail.com

## Horizontally stack two videos with the same size, using ffmpeg
# Stream mapping  (example):
#   Stream #0:0 (h264) -> hstack:input0 (graph 0)
#   Stream #1:0 (h264) -> hstack:input1 (graph 0)
#   hstack (graph 0) -> Stream #0:0 (libx264)
#   Stream #0:1 -> #0:1 (aac (native) -> aac (native))

out_video='output.mp4'
if [[ $# -gt 2 ]]; then
	out_video=$3
fi
echo "save into $out_video"

ffmpeg -i $1 -i $2 -filter_complex hstack $out_video

