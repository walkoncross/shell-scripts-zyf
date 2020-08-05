#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import argparse
import sys
import os
import os.path as osp
import glob

import ffmpeg


def get_video_stream_info(video_filename):
    try:
        probe = ffmpeg.probe(video_filename)
    except ffmpeg.Error as e:
        print(e.stderr, file=sys.stderr)
        sys.exit(1)

    video_stream = next(
        (stream for stream in probe['streams'] if stream['codec_type'] == 'video'), None)
    if video_stream is None:
        print('No video stream found', file=sys.stderr)
        sys.exit(1)

    return video_stream


def stack_two_videos(video1, video2, save_dir='./', vstack=False):
    if not save_dir:
        save_dir = os.getcwd() + '/stacked_videos'

    if not osp.isdir(save_dir):
        os.makedirs(save_dir)

    basename1 = osp.splitext(osp.basename(video1))[0]
    basename2 = osp.splitext(osp.basename(video2))[0]
    output = '{}_and_{}_{}stack.mp4'.format(
        basename1, basename2, 'v' if vstack else 'h')
    output = osp.join(save_dir, output)

    print('===> Video1: ', video1)
    video1_info = get_video_stream_info(video1)

    width1 = int(video1_info['width'])
    height1 = int(video1_info['height'])
    num_frames_1 = int(video1_info['nb_frames'])
    print('width: {}'.format(width1))
    print('height: {}'.format(height1))
    print('num_frames: {}'.format(num_frames_1))

    print('===> Video2: ', video2)
    video2_info = get_video_stream_info(video2)

    width2 = int(video2_info['width'])
    height2 = int(video2_info['height'])
    num_frames_2 = int(video2_info['nb_frames'])
    print('width: {}'.format(width2))
    print('height: {}'.format(height2))
    print('num_frames: {}'.format(num_frames_2))

    print('===> Stacked output video: ', output)

    in_stream1 = ffmpeg.input(video1)
    in_stream2 = ffmpeg.input(video2)

    video1 = in_stream1.video
    audio1 = in_stream1.audio
    video2 = in_stream2.video
    # audio2 = in_stream2.audio

    if vstack:
        if width1 == width2:
            print(
                '---> The two videos has the same width, simply stack video1 and video2.')
            stacked_video = ffmpeg.filter((video1, video2), 'vstack')
        else:
            print('---> The two videos has different widths, resize video2 to have the same width as video2,'
                  ' and then stack video1 and resize video2.')
            video2_resized = video2.filter('scale', w=str(width1), h='-2')

            stacked_video = ffmpeg.filter((video1, video2_resized), 'vstack')
    else:
        if height1 == height2:
            print(
                '---> The two videos has the same height, simply stack video1 and video2')
            stacked_video = ffmpeg.filter((video1, video2), 'hstack')
        else:
            print('---> The two videos has different height, resize video2 to have the same height as video2,'
                  ' and then stack video1 and resize video2.')

            video2_resized = video2.filter('scale', w='-2', h=str(height1))

            stacked_video = ffmpeg.filter((video1, video2_resized), 'hstack')

    out_stream = ffmpeg.output(stacked_video, audio1, output)
    cmdline = ffmpeg.compile(out_stream)
    print('===> ffmpeg cmdline:', cmdline)

    out_stream.run()


def stack_video_list(video_list, save_dir='./', vstack=False):
    n_videos = len(video_list)

    for i in range(n_videos):
        for j in range(i+1, n_videos):
            print('===> stack {} and {}'.format(video_list[i], video_list[j]))
            stack_two_videos(video_list[i], video_list[j], save_dir, vstack)


def stack_video_groups(video_group_list, save_dir='./', vstack=False):
    for group in video_group_list:
        if len(group) > 1:
            print('===> stack group: ', group)
            stack_video_list(group, save_dir, vstack)


def get_video_groups(input_dir, suffixes=None, group_pattern_delimiter='_'):
    default_video_extensions = ['mp4', 'mov', 'avi', 'mkv']

    if not suffixes:
        suffix_list = default_video_extensions
    elif isinstance(suffixes, str):
        suffix_list = suffixes.split(',')
    elif isinstance(suffixes, list):
        suffix_list = suffixes
    else:
        print('suffixes must be of str or list type')
        exit(1)

    file_list = os.listdir(input_dir)
    print('===> file list: ', file_list)

    tmp_list = list()
    for fn in file_list:
        fn = osp.join(input_dir, fn)
        if not osp.isfile(fn):
            continue

        basename, ext = osp.splitext(fn)
        if not ext:
            continue

        if ext[1:] not in suffix_list:
            continue

        group_name = basename.split(group_pattern_delimiter)[0]

        tmp_list.append(dict(fn=fn, gn=group_name))

    print('===> video file list: ', tmp_list)

    group_dict = dict()
    for item in tmp_list:
        if item['gn'] not in group_dict:
            group_dict[item['gn']] = [item['fn']]
        else:
            group_dict[item['gn']].append(item['fn'])

    print('===> video groups: ', group_dict)

    group_list = list(group_dict.values())

    return group_list


def list_and_stack_video_groups(input_dir, save_dir='', suffixes='', group_pattern_delimiter='_', vstack=False):
    group_list = get_video_groups(
        input_dir, suffixes, group_pattern_delimiter)
    print('===> group list: ', group_list)
    stack_video_groups(group_list, save_dir, vstack)


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
        args.input_dir, args.save_dir, args.suffixes, args.delimiter, args.vstack)
