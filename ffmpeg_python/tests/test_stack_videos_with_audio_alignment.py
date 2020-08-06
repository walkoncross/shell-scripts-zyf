#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import argparse
import sys
import os
import os.path as osp
import json

TEST_DIR = osp.dirname(__file__)
print('===> TEST_DIR: ', TEST_DIR)
print('===> TEST FILE:', __file__)
sys.path.append(osp.dirname(TEST_DIR))

from ffmpeg_python_tools import stack_two_videos_with_trim_files


def _make_argparser():
    parser = argparse.ArgumentParser(description='stack two videos horizontally (left-right,default)'
                                     'or veritically (top-bottom, if set -vs or --vstack)')
    parser.add_argument('-vs', '--vstack',
                        dest='vstack',
                        action='store_true',
                        default=False,
                        help='If set, stack vertically (top-bottom), else stack horizontally (left-right)')
    parser.add_argument('-na', '--no_align',
                        dest='try_align',
                        action='store_false',
                        default=True,
                        help='Do not align audio')
    parser.add_argument('video1', help='Input filename for the first video')
    parser.add_argument('video2', help='Input filename for the second video')
    parser.add_argument('save_dir', nargs='?', default=os.getcwd(),
                        help='[Optional] Directory to save output video file, default os.getcwd(),'
                        'output filename: {save_dir}/{video1}_and_{video2}_[h/v]stack.mp4')
    parser.add_argument('trim_json1', nargs='?', default='', help='Input filename for the first video')
    parser.add_argument('trim_json2', nargs='?', default='', help='Input filename for the second video')

    return parser


if __name__ == '__main__':
    parser = _make_argparser()
    args = parser.parse_args()
    print('===> args: ', args)

    video_file = stack_two_videos_with_trim_files(
                        args.video1,
                        args.video2,
                        args.save_dir,
                        args.vstack,
                        args.trim_json1,
                        args.trim_json2,
                        args.try_align
                    )
    print('===> Stacked video file saved into: ', video_file)
