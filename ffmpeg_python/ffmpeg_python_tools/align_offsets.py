#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import os
import os.path as osp

import json


def get_align_offsets(
        start_time1, end_time1, 
        start_time2, end_time2, 
        verbose=0):
    """
    Get align time offsets for two videos or audios.

    return:
        align_info_dict: dict 
            a dict of time offsets infos, in the format of:
            {
                "time_offset1": time_offset1,
                "time_offset2": time_offset1,
                "time_duration": time_duration,
            }
    """
    trim_duration1 = end_time1 - start_time1
    trim_duration2 = end_time2 - start_time2

    start_time_diff = start_time2 - start_time1
    duration_diff = trim_duration2 - trim_duration1

    trim_margin = 0.1
    time_offset1 = start_time1 - trim_margin
    time_duration = trim_duration1

    left_margin = trim_margin
    right_margin = trim_margin

    if time_offset1 < 0:
        left_margin = -time_offset1  # left margin
        time_offset1 = 0

    if abs(duration_diff) < 1:  # duration_diff < 1 second, try to align
        # if start_time_diff > 0:
        #     time_offset1 = 0
        # else:
        #     time_offset1 = -start_time_diff
        time_offset2 = time_offset1 + start_time_diff
        time_duration = min(trim_duration1, trim_duration2) + \
            left_margin + right_margin

        if time_offset2 < 0:
            time_duration -= time_offset2
            time_offset1 -= time_offset2
            time_offset2 = 0
    else:
        time_offset2 = time_offset1
        time_duration += left_margin + right_margin

    align_info_dict = {
        "time_offset1": time_offset1,
        "time_offset2": time_offset1,
        "time_duration": time_duration,
    }

    print('===> align info: ')
    print(json.dumps(align_info_dict, indent=2))

    return align_info_dict


__all__ = ["get_align_offsets"]