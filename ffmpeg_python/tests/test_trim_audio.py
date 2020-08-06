#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import os
import os.path as osp
import sys
import json
import argparse


TEST_DIR = osp.dirname(__file__)
print('===> TEST_DIR: ', TEST_DIR)
sys.path.append(osp.dirname(TEST_DIR))

from ffmpeg_python_tools import get_audio_trim_info


def _make_argparser():
    parser = argparse.ArgumentParser(
        description='Get audio trim infos (trim_start_time, trim_end_time, trim_duration, etc.).')
    parser.add_argument('-f', '--force', '--ow', '--overwrite',
                        dest='force_overwrite',
                        default=False,
                        action='store_true',
                        help='Force to overwrite existing audio file and trim info json file.')
    parser.add_argument('-ml', '--min_level', '--minlevel',
                        dest='trim_min_level',
                        type=float,
                        default=0,
                        help='Min level (ratio to the max value of the audio data sequence) '
                        'to trim from both the beginning and from the end, default: 0.0')
    parser.add_argument('audio', help='Input audio file')
    parser.add_argument('save_dir',
                        type=str,
                        default='',
                        nargs='?',
                        help='[Optional] Directory to save the output audio file, default: the same path as input audio file.')
    return parser

if __name__ == '__main__':
    parser = _make_argparser()
    args = parser.parse_args()
    print('===> Args: ', args)

    get_audio_trim_info(
        args.audio,
        args.trim_min_level,
        force_trim=args.force_overwrite,
        verbose=True
    )