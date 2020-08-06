#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import argparse
import sys
import os
import os.path as osp

from ffmpeg_python_tools import get_video_groups, stack_two_videos


def stack_video_list_in_pairs(root_dir, video_list, save_dir='./', vstack=False):
    n_videos = len(video_list)

    for i in range(n_videos):
        for j in range(i+1, n_videos):
            print('===> stack {} and {}'.format(video_list[i], video_list[j]))
            video_file = stack_two_videos(
                osp.join(root_dir, video_list[i]),
                osp.join(root_dir, video_list[j]),
                save_dir, vstack
            )
            print('===> Stacked video file saved into: ', video_file)


def stack_video_groups(root_dir, video_group_list, save_dir='./', vstack=False):
    for group in video_group_list:
        if len(group) > 1:
            print('===> stack group: ', group)
            stack_video_list_in_pairs(root_dir, group, save_dir, vstack)


def list_and_stack_video_groups(root_dir, save_dir='', suffixes='', group_pattern_delimiter='_', vstack=False):
    group_list = get_video_groups(
        root_dir, suffixes, group_pattern_delimiter)
    print('===> group list: ', group_list)
    stack_video_groups(root_dir, group_list, save_dir, vstack)


def _make_argparser():
    input_dir = './'
    save_dir = osp.join(input_dir + 'stacked_videos')
    parser = argparse.ArgumentParser(description='stack two videos horizontally (left-right,default)'
                                     'or veritically (top-bottom, if set -vs or --vstack)')
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
    parser.add_argument('save_dir',
                        nargs='?',
                        default=save_dir,
                        help='[Optional] Directory to save output video file, default: ' + save_dir +
                        ', output filename: {save_dir}/{video1}_and_{video2}_[h/v]stack.mp4')

    return parser


if __name__ == '__main__':
    parser = _make_argparser()
    args = parser.parse_args()
    print('===> args: ', args)

    list_and_stack_video_groups(
        args.input_dir,
        args.save_dir,
        args.suffixes,
        args.delimiter,
        args.vstack
    )
