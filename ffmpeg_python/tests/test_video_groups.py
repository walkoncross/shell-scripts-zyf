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

from ffmpeg_python_tools import get_video_groups


def _make_argparser():
    input_dir = './'
    parser = argparse.ArgumentParser(
        description='Get list of video groups with specified filename pattern')
    parser.add_argument('-vs', '--vstack',
                        dest='vstack',
                        action='store_true',
                        default=False,
                        help='If set, stack vertically (top-bottom), else stack horizontally (left-right)')
    parser.add_argument('-s', '--suffixes', '--video_suffixes',
                        dest='suffixes',
                        default='mp4,mov,avi,mkv',
                        help='Video extension suffixes, default: "mp4,mov,avi,mkv"')
    parser.add_argument('-d', '--delimiter',
                        dest='delimiter',
                        default='_',
                        help='Group pattern delimiter, video filenames should have pattern:'
                                ' {group_name}{delimiter}{index}.{suffix}')
    parser.add_argument('input_dir',
                        nargs='?',
                        default=input_dir,
                        help='[Optional] Input dir to glob video files, default: '+input_dir)

    return parser


if __name__ == '__main__':
    parser = _make_argparser()
    args = parser.parse_args()
    print('===> args: ', args)

    get_video_groups(
        args.input_dir, args.suffixes, args.delimiter, verbose=True)
