#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import argparse
import sys
import os
import os.path as osp

import ffmpeg
import librosa

import json
from ffmpeg_python_tools import extract_audio_and_get_trim_info, stack_two_videos_with_trim_dicts


def _make_argparser():
    parser = argparse.ArgumentParser(description='stack two videos horizontally (left-right,default)'
                                     'or veritically (top-bottom, if set -vs or --vstack)')
    parser.add_argument('-vs', '--vstack',
                        dest='vstack',
                        action='store_true',
                        default=False,
                        help='If set, stack vertically (top-bottom), else stack horizontally (left-right)')
    parser.add_argument('video1', help='Input filename for the first video')
    parser.add_argument('video2', help='Input filename for the second video')
    parser.add_argument('save_dir', nargs='?', default=os.getcwd(),
                        help='[Optional] Directory to save output video file, default os.getcwd(),'
                        'output filename: {save_dir}/{video1}_and_{video2}_[h/v]stack.mp4')

    return parser


if __name__ == '__main__':
    parser = _make_argparser()
    args = parser.parse_args()
    print('===> Args: ', args)

    _, trim_info1 = extract_audio_and_get_trim_info(
        args.video1,
        save_dir=None,
        ext_format='mp3',
        trim_min_level=0.01,
        force_overwrite=False,
        verbose=True
    )

    _, trim_info2 = extract_audio_and_get_trim_info(
        args.video2,
        save_dir=None,
        ext_format='mp3',
        trim_min_level=0.01,
        force_overwrite=False,
        verbose=True
    )

    video_file = stack_two_videos_with_trim_dicts(
        args.video1,
        args.video2,
        args.save_dir,
        args.vstack,
        trim_info1,
        trim_info2,
        verbose=True
    )
    print('===> Stacked video file saved into: ', video_file)
