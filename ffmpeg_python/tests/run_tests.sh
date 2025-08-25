#!/bin/bash
python tests/test_align_videos.py data/0.mp4  data/0_1.mp4
python tests/test_stream_info.py data/0.mp4
python tests/test_extract_audio.py data/0.mp4     
python tests/test_extract_audio_and_get_trim_info.py data/0.mp4
python tests/test_video_groups.py data
python tests/test_stack_videos.py data/0.mp4 data/0_1.mp4
python tests/test_stack_videos_with_audio_alignment.py  data/0.mp4  data/0_1.mp4
python tests/test_trim_audio.py  data/0.mp4