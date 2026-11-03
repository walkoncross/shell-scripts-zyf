#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import os.path as osp
import sys


TEST_DIR = osp.dirname(__file__)
print('===> TEST_DIR: ', TEST_DIR)
print('===> TEST FILE:', __file__)
sys.path.append(osp.dirname(TEST_DIR))

from ffmpeg_python_tools import get_video_stream_info


if __name__=='__main__':
    get_video_stream_info(sys.argv[1], verbose=1)