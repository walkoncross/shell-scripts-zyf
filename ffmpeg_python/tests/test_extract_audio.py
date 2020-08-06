#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import argparse
import sys
import os
import os.path as osp


TEST_DIR = osp.dirname(__file__)
print('===> TEST_DIR: ', TEST_DIR)
sys.path.append(osp.dirname(TEST_DIR))

from ffmpeg_python_tools import extract_audio_into_file


def _make_argparser():
    parser = argparse.ArgumentParser(
        description='Extract audio channels from video and save into mp3/wav/aac file.')
    parser.add_argument('-f', '--force', '--ow', '--overwrite',
                        type=bool,
                        dest='force_overwrite',
                        default=False,
                        action='store_true',
                        help='Force to overwrite existing audio file.')
    parser.add_argument('-fmt', '--format',
                        type=str,
                        dest='ext_format',
                        default='mp3',
                        help='Extracted audio file extension format, support wav/mp3/aac, default: mp3')
    parser.add_argument('video', help='Input video filename')
    parser.add_argument('save_dir',
                        type=str,
                        default='',
                        nargs='?',
                        help='[Optional] Directory to save the output audio file, default: the same path as input audio file.')
    return parser


if __name__ == '__main__':
    parser = _make_argparser()
    args = parser.parse_args()
    print('===> Args: ', args)

    audio_file = extract_audio_into_file(
        args.video,
        args.save_dir,
        args.ext_format,
        args.force_overwrite
    )
    print('===> Extraced audio file saved into: ', audio_file)