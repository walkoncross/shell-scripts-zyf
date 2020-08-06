#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import sys
import os
import os.path as osp

import json


def get_video_filelist(root_dir,
                       suffixes=None,
                       verbose=False):
    """
    Get video filelist under root_dir with extension format in suffixes.

    @params:
        root_dir: str
            root dir to glob video files
        suffixes: str or list of str
            video extension formats to glob, i.e. `mp4,avi,mov,mkv` or ['mp4','avi','mov','mkv']
        verbose: bool
            Print verbose information, mainly for debug.

    @return:
        video_filelist: list of str
            list of video files
    """
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

    file_list = os.listdir(root_dir)
    if verbose:
        print('===> file list: ', file_list)

    video_filelist = list()
    for fn in file_list:
        full_fn = osp.join(root_dir, fn)
        if not osp.isfile(full_fn):
            continue

        _, ext = osp.splitext(fn)
        if not ext:
            continue

        if ext[1:] not in suffix_list:
            continue

        video_filelist.append(fn)

    if verbose:
        print('===> video file list: ', video_filelist)

    return video_filelist


def get_video_groups(video_filelist,
                     group_pattern_delimiter='_',
                     verbose=False):
    """
    Get video groups

    @params:
        video_filelist: list of str
            list of video files
        group_pattern_delimiter: str
            video group pattern delimiter, grouped videos have name patter: {gn}{delimiter}{fn}.{ext}
        verbose: bool
            Print verbose information, mainly for debug.

    @return:
        group_list: list of list of str
            list of groups
    """
    tmp_list = []
    for fn in video_filelist:
        basename, _ = osp.splitext(fn)
        group_name = basename.split(group_pattern_delimiter)[0]

        tmp_list.append(dict(fn=fn, gn=group_name))

    group_dict = dict()
    for item in tmp_list:
        if item['gn'] not in group_dict:
            group_dict[item['gn']] = [item['fn']]
        else:
            group_dict[item['gn']].append(item['fn'])

    group_list = list(group_dict.values())

    if verbose:
        print('===> video groups: ', group_dict)
        print('===> video group list: ', group_list)

    return group_list


___all__ = ['get_video_filelist', 'get_video_groups']
