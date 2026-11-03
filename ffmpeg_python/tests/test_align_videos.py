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
print('===> TEST FILE:', __file__)
sys.path.append(osp.dirname(TEST_DIR))

from ffmpeg_python_tools import get_video_align_info
from ffmpeg_python_tools.utils import  join_two_filenames


def _make_argparser():
    parser = argparse.ArgumentParser(
        description='Get video/audio alignment infos (time_offset1, time_offset2, time_duration).')
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
    parser.add_argument('input1', help='the first input audio/video file')
    parser.add_argument('input2', help='the second input audio/video file')
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

    align_info_dict = get_video_align_info(
                            args.input1,
                            args.input2,
                            args.trim_min_level,
                            force_trim=args.force_overwrite,
                            verbose=True
                        )
    
    joined_name = join_two_filenames(args.input1, args.input2, '_and_')

    align_info_json = joined_name + '.align_info.json'
    align_info_json = osp.join(args.save_dir, align_info_json)

    print('===> save align info into: ', align_info_json)

    fp = open(align_info_json, 'w')
    json.dump(align_info_json, fp, indent=2)
    fp.close()