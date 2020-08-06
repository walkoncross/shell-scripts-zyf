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

from ffmpeg_python_tools import get_align_offsets, stack_two_videos
from ffmpeg_python_tools.utils import join_two_filenames


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

    if not trim_info_file1:
        trim_info_file1 = osp.splitext(video1)[0] + '.trim_info.json'

    if not trim_info_file2:
        trim_info_file2 = osp.splitext(video2)[0] + '.trim_info.json'

    if osp.isfile(trim_info_file1) and osp.isfile(trim_info_file1):
        if verbose:
            print('===> load trim info from: ', trim_info_file1)

        fp = open(trim_info_file1, 'r')
        video1_trim_info = json.load(fp)
        fp.close()

        if verbose:
            print('===> load trim info from: ', trim_info_file2)

        fp = open(trim_info_file2, 'r')
        video2_trim_info = json.load(fp)
        fp.close()

        align_info_dict = get_align_offsets(
            video1_trim_info['trim_start_time'], video1_trim_info['trim_end_time'],
            video2_trim_info['trim_start_time'], video2_trim_info['trim_end_time'],
            verbose=verbose
        )

        joined_name = join_two_filenames(video1, video2, '_and_')

        align_info_json = joined_name + '.align_info.json'
        align_info_json = osp.join(save_dir, align_info_json)

        if verbose:
            print('===> save align info into: ', align_info_json)

        fp = open(align_info_json, 'w')
        json.dump(align_info_json, fp, indent=2)
        fp.close()

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
    parser.add_argument('trim_json1', nargs='?', default='', help='Input filename for the first video')
    parser.add_argument('trim_json2', nargs='?', default='', help='Input filename for the second video')

    return parser


if __name__ == '__main__':
    parser = _make_argparser()
    args = parser.parse_args()
    print('===> args: ', args)

    stack_two_videos_with_audio_alignment(
        args.video1,
        args.video2,
        args.save_dir,
        args.vstack,
        args.trim_json1,
        args.trim_json2,
        args.try_align
    )
