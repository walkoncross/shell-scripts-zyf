docker run --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=2,3 --shm-size 8G  -it --rm dev:v1 /bin/bash

