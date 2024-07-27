ffmpeg -re -i $1 \
  -c:v libx264 -an -f rtp rtp://127.0.0.1:5004 \
  -sdp_file stream_video_only.sdp

