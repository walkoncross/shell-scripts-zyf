ffmpeg -re -i $1 \
  -c:v libx264 -an -f rtp rtp://127.0.0.1:5004 \
  -c:a aac -vn -f rtp rtp://127.0.0.1:5002 \
  -sdp_file stream.sdp

