# ffmpeg python scripts
@author: zhaoyafei0210@gmail.com

Moved into: [github repo](https://github.com/walkoncross/ffmpeg-python-tools)

Table of Contents:
- [ffmpeg python scripts](#ffmpeg-python-scripts)
  - [ffmpeg](#ffmpeg)
  - [ffmpeg-python](#ffmpeg-python)
  - [scripts](#scripts)
  
## ffmpeg
[ffmpeg online documentation](http://ffmpeg.org/documentation.html)

## ffmpeg-python
- Github:	
  https://github.com/kkroening/ffmpeg-python
- API Reference:	
  https://kkroening.github.io/ffmpeg-python/

## scripts
- extract audio from video and save into file: [ffmpeg_extract_audio](./ffmpeg_extract_audio.py)
  - for help info: ```python ffmpeg_extract_audio.py -h```
- extract audio from video and save into file, and get trim info: [ffmpeg_extract_audio_and_get_trim_info](./ffmpeg_extract_audio_and_get_trim_info.py)
  - for help info: ```python ffmpeg_extract_audio_and_get_trim_info.py -h```
- stack two videos: [ffmpeg_stack_videos](./ffmpeg_stack_videos.py)
  - for help info: ```python ffmpeg_stack_videos.py -h```
- stack two videos with audio alignment: [ffmpeg_stack_videos_with_audio_alignment](./ffmpeg_stack_videos_with_audio_alignment.py)
  - for help info: ```python ffmpeg_stack_videos_with_audio_alignment.py -h```
- stack two videos with audio alignment using trim info json: [ffmpeg_stack_videos_with_trim_files](./ffmpeg_stack_videos_with_trim_files.py)
  - for help info: ```python ffmpeg_stack_videos_with_trim_files.py -h```
- stack groups of videos : [ffmpeg_stack_video_groups](./ffmpeg_stack_video_groups.py)
  - for help info: ```python ffmpeg_stack_video_groups.py -h```
- stack groups of videos with audio alignment: [ffmpeg_stack_video_groups_with_audio_alignment](./ffmpeg_stack_video_groups_with_audio_alignment.py)
  - for help info: ```python ffmpeg_stack_video_groups_with_audio_alignment.py -h```
