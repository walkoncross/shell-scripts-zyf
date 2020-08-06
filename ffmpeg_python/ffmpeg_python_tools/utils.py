#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import os
import os.path as osp

import json


def join_two_filenames(file1, file2, join_str='_and_'):
    basename1 = osp.splitext(osp.basename(file1))[0]
    basename2 = osp.splitext(osp.basename(file2))[0]
    joined_name = basename1 + join_str + basename2

    return joined_name

def join_filename_list(file_list, join_str='_and_'):
    joined_name = ''
    for filename in file_list:
        basename = osp.splitext(osp.basename(filename))[0]
        if not joined_name:
            joined_name = basename
        else:
            joined_name += join_str + basename

    return joined_name

__all__ = ['join_two_filenames', 'join_filename_list']