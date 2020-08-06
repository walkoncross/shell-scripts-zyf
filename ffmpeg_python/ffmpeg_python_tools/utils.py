#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import os
import os.path as osp

import json


def join_two_filenames(filename1, filename2, join_str='_and_'):
    """
    Join base parts (without extension) of two filenames to form a concated string.

    @params:
        filename1: str
        filename2: str
            input filenames
        join_str: str
            join str in-between

    @return:
        joined_name: str
            joined_name = basename1 + join_str + basename2
    """
    basename1 = osp.splitext(osp.basename(filename1))[0]
    basename2 = osp.splitext(osp.basename(filename2))[0]
    joined_name = basename1 + join_str + basename2

    return joined_name


def join_filename_list(filename_list, join_str='_and_'):
    """
    Join base parts (without extension) of a list of filenames to form a concated string.

    @params:
        filename_list: list of str
            input filenames
        join_str: str
            join str in-between

    @return:
        joined_name: str
            joined_name = basename1 + join_str + basename2 + join_str + ...
    """
    joined_name = ''
    for filename in filename_list:
        basename = osp.splitext(osp.basename(filename))[0]
        if not joined_name:
            joined_name = basename
        else:
            joined_name += join_str + basename

    return joined_name


__all__ = ['join_two_filenames', 'join_filename_list']
