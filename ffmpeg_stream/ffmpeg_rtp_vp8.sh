ffmpeg -re -i $1 \
  -c:v libvpx -an -f rtp rtp://127.0.0.1:5004 \
  -c:a libopus -vn -f rtp rtp://127.0.0.1:5002 \
  -sdp_file stream.sdp

