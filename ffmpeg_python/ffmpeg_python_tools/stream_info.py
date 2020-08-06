#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import sys
import json
import ffmpeg


def get_video_stream_info(video_filename, verbose=0):
    """
    get video stream info.

    return:
        video_stream_info: dict
            a dict of video stream info, looks like:
            {
                "index": 0,
                "codec_name": "h264",
                "codec_long_name": "H.264 / AVC / MPEG-4 AVC / MPEG-4 part 10",
                "profile": "Main",
                "codec_type": "video",
                "codec_time_base": "240169/8680000",
                "codec_tag_string": "avc1",
                "codec_tag": "0x31637661",
                "width": 1018,
                "height": 928,
                "coded_width": 1024,
                "coded_height": 928,
                "has_b_frames": 2,
                "sample_aspect_ratio": "1:1",
                "display_aspect_ratio": "509:464",
                "pix_fmt": "yuv420p",
                "level": 40,
                "color_range": "tv",
                "color_space": "bt709",
                "color_transfer": "bt709",
                "color_primaries": "bt709",
                "chroma_location": "left",
                "refs": 1,
                "is_avc": "true",
                "nal_length_size": "4",
                "r_frame_rate": "217/12",
                "avg_frame_rate": "4340000/240169",
                "time_base": "1/90000",
                "start_pts": 0,
                "start_time": "0.000000",
                "duration_ts": 2161521,
                "duration": "24.016900",
                "bit_rate": "830714",
                "bits_per_raw_sample": "8",
                "nb_frames": "434",
                "disposition": {
                    "default": 1,
                    "dub": 0,
                    "original": 0,
                    "comment": 0,
                    "lyrics": 0,
                    "karaoke": 0,
                    "forced": 0,
                    "hearing_impaired": 0,
                    "visual_impaired": 0,
                    "clean_effects": 0,
                    "attached_pic": 0,
                    "timed_thumbnails": 0
                },
                "tags": {
                    "creation_time": "2020-07-31T06:13:15.000000Z",
                    "language": "und",
                    "handler_name": "VideoHandler"
                }
                }
    """
    if verbose:
        print('===> input video: ', video_filename)

    try:
        probe = ffmpeg.probe(video_filename)
    except ffmpeg.Error as e:
        print(e.stderr, file=sys.stderr)
        sys.exit(1)

    video_stream_info = next(
        (stream for stream in probe['streams'] if stream['codec_type'] == 'video'), None)
    if video_stream_info is None:
        print('No video stream found', file=sys.stderr)
        sys.exit(1)

    if verbose:
        print('===> video_stream_info')
        print(json.dumps(video_stream_info, indent=2))

    return video_stream_info


__all__ = ['get_video_stream_info']