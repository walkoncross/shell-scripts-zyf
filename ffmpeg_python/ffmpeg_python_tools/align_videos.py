#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import os
import os.path as osp

import json
from .align_offsets import get_align_offsets
from .utils import join_two_filenames


def get_video_align_info(
        video1, video2,
        trim_min_level=0.01,
        force_trim=False,
        verbose=0):
    """
    Get align timeoffsets for two videos.

    return:
        align_info_dict: dict 
            a dict of time offsets infos, in the format of:
            {
                "time_offset1": time_offset1,
                "time_offset2": time_offset1,
                "time_duration": time_duration,
            }
    """
    rootname1 = osp.splitext(video1)[0]
    rootname2 = osp.splitext(video2)[0]

    trim_info_json1 = rootname1 + '.trim_info.json'
    trim_info_json2 = rootname2 + '.trim_info.json'

    align_info_dict = dict()

    if not osp.isfile(trim_info_json1) or force_trim:
        video1_trim_info = extract_audio_and_get_trim_info(
            video1, save_dir=None,
            ext_format='mp3',
            trim_min_level=trim_min_level,
            force_overwrite=True)

        if verbose:
            print('===> save trim info into: ', trim_info_json1)

        fp = open(trim_info_json1, 'w')
        json.dump(video1_trim_info, fp, indent=2)
        fp.close()
    else:
        if verbose:
            print('===> load trim info from: ', trim_info_json1)

        fp = open(trim_info_json1, 'r')
        video1_trim_info = json.load(fp)
        fp.close()

    if verbose:
        print('===> trim info: ', json.dumps(video1_trim_info, indent=2))

    if not osp.isfile(trim_info_json2) or force_trim:
        video2_trim_info = extract_audio_and_get_trim_info(
            video2, save_dir=None,
            ext_format='mp3',
            trim_min_level=trim_min_level,
            force_overwrite=True)

        if verbose:
            print('===> save trim info into: ', trim_info_json2)

        fp = open(trim_info_json2, 'w')
        json.dump(video2_trim_info, fp, indent=2)
        fp.close()
    else:
        if verbose:
            print('===> load trim info from: ', trim_info_json2)

        fp = open(trim_info_json2, 'r')
        video2_trim_info = json.load(fp)
        fp.close()

    if verbose:
        print('===> trim info: ', json.dumps(video2_trim_info, indent=2))

    align_info_dict = get_align_offsets(
        video1_trim_info['trim_start_time'], video1_trim_info['trim_end_time'],
        video2_trim_info['trim_start_time'], video2_trim_info['trim_end_time'],
        verbose=verbose
    )

    if verbose:
        print('===> align info: ')
        print(json.dumps(align_info_dict, indent=2))

    return align_info_dict


__all__ = ["get_video_align_info"]
