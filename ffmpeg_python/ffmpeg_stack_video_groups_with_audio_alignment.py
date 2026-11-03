#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import argparse
import sys
import os
import os.path as osp
import json

from ffmpeg_python_tools import get_video_filelist, get_video_groups, extract_audio_and_get_trim_info, stack_two_videos_with_trim_dicts


def stack_video_list_in_pairs(root_dir,
                              video_list,
                              trim_info_dict_list,
                              save_dir='./',
                              vstack=False,
                              verbose=False):
    n_videos = len(video_list)

    for i in range(n_videos):
        for j in range(i+1, n_videos):
            print('===> stack {} and {}'.format(video_list[i], video_list[j]))
            video_file = stack_two_videos_with_trim_dicts(
                osp.join(root_dir, video_list[i]),
                osp.join(root_dir, video_list[j]),
                save_dir, vstack,
                video1_trim_info_dict=trim_info_dict_list[i],
                video2_trim_info_dict=trim_info_dict_list[j],
                verbose=verbose
            )
            print('===> Stacked video file saved into: ', video_file)


def stack_video_groups(root_dir,
                       video_group_list,
                       trim_info_dict_list_list,
                       save_dir='./',
                       vstack=False,
                       verbose=False):
    for i, group in enumerate(video_group_list):
        if len(group) > 1:
            print('===> stack group: ', group)
            stack_video_list_in_pairs(root_dir,
                                      group,
                                      trim_info_dict_list_list[i],
                                      save_dir,
                                      vstack,
                                      verbose=verbose
                                      )


def list_and_stack_video_groups(root_dir,
                                save_dir='',
                                suffixes='',
                                group_pattern_delimiter='_',
                                vstack=False,
                                verbose=False):

    if not osp.exists(root_dir):
        print('===> root dir does not exist: ', root_dir)
        exit(1)
    
    if not osp.exists(save_dir):
        print('===> save dir does not exist, make it: ', save_dir)
        os.makedirs(save_dir)

    video_filelist = get_video_filelist(root_dir, suffixes, verbose=verbose)
    print('===> video_filelist: ', video_filelist)

    group_list = get_video_groups(
        video_filelist, group_pattern_delimiter, verbose=verbose)
    print('===> group list: ', group_list)

    # Get *.trim_info.json
    trim_info_dict_list_list = []
    for group in group_list:
        trim_info_dict_list = []
        for fn in group:
            full_name = osp.join(root_dir, fn)
            print('===> full path: ', full_name)
            trim_info_json = osp.splitext(full_name)[0]+'.trim_info.json'

            if not osp.isfile(trim_info_json):
                _, trim_info_dict = extract_audio_and_get_trim_info(
                    full_name,
                    save_dir=None,
                    ext_format='.mp3',
                    trim_min_level=0.01,
                    force_overwrite=False,
                    verbose=verbose
                )

                fp = open(trim_info_json, 'w')
                json.dump(trim_info_dict, fp)
                fp.close()
            else:
                fp = open(trim_info_json, 'r')
                trim_info_dict = json.load(fp)
                fp.close()

            trim_info_dict_list.append(trim_info_dict)
        trim_info_dict_list_list.append(trim_info_dict_list)

    stack_video_groups(root_dir,
                       group_list,
                       trim_info_dict_list_list,
                       save_dir,
                       vstack)


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
        args.vstack,
        verbose=True
    )
