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
sys.path.append(osp.dirname(TEST_DIR))

from ffmpeg_python_tools import stack_two_videos



def stack_two_videos_with_audio_alignment(video1, video2,
                                          save_dir='./',
                                          vstack=False,
                                          trim_info_file1=None,
                                          trim_info_file2=None,
                                          verbose=0):
    """
    stack two videos and try to align their audio timeline.

    return:
        output_path: str
            path to output video file.
    """
    if not save_dir:
        save_dir = os.getcwd()

    if not osp.isdir(save_dir):
        os.makedirs(save_dir)

    basename1 = osp.splitext(osp.basename(video1))[0]
    basename2 = osp.splitext(osp.basename(video2))[0]

    if osp.isfile(trim_info_file1) and osp.isfile(trim_info_file1):

        align_info_dict = get_audio_align_info(
            trim_info_file1, trim_info_file2, save_dir)
        output_path = stack_two_videos(video1, video2,
                                       save_dir,
                                       vstack,
                                       align_info_dict['time_offset1'],
                                       align_info_dict['time_offset1'],
                                       align_info_dict['time_duration'],
                                       verbose=verbose)
    else:
        output_path = stack_two_videos(video1, video2,
                                       save_dir,
                                       vstack,
                                       verbose=verbose)

    return output_path

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

    return parser


if __name__ == '__main__':
    parser = _make_argparser()
    args = parser.parse_args()

    stack_two_videos_with_audio_alignment(
        args.video1,
        args.video2,
        args.save_dir,
        args.vstack,
        args.try_align
    )
