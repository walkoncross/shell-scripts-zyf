#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import argparse
import ffmpeg
import sys
import os
import os.path as osp


def extract_audio_into_file(video, save_dir='', ext_format='mp3',
                            force_overwrite=False):
    print('===> Video: ', video)
    audio_file = osp.splitext(video)[0]+'.'+ext_format

    if save_dir:
        basename = osp.splitext(audio_file)
        if not osp.isdir(save_dir):
            os.makedirs(save_dir)
        audio_file = osp.join(save_dir, basename)
    print('===> audio_file: ', audio_file)

    if not osp.isfile(audio_file) or force_overwrite:
        in_stream = ffmpeg.input(video)

        out_stream = ffmpeg.output(in_stream.audio, audio_file)
        cmdline = ffmpeg.compile(out_stream)
        print('===> ffmpeg cmdline:', cmdline)
        out_stream.run()
    else:
        print('===> audio file already exists, skip')

    return audio_file


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

    extract_audio_into_file(
        args.video,
        args.save_dir,
        args.ext_format,
        args.force_overwrite
    )
