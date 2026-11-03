# brew install gstreamer gtk+3
input_file="$1"
output_file="${input_file%.c}.bin"

clang $@ $(pkg-config --cflags --libs gstreamer-1.0 gstreamer-audio-1.0 gstreamer-pbutils-1.0 gtk+-3.0) -o $output_file
