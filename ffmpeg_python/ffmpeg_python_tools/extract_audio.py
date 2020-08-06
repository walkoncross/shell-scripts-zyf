#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import os
import os.path as osp

import ffmpeg

import json
from .trim_audio import get_audio_trim_info


def extract_audio_into_file(video, save_dir='', ext_format='mp3',
                            force_overwrite=False, verbose=0):
    """
    extract_audio_into_file:

    return:
        audio_file: str,
            path of saved audio file.
    """
    if verbose:
        print('===> Video: ', video)

    if not ext_format.startswith('.'):
        ext_format = '.' + ext_format

    audio_file = osp.splitext(video)[0]+ext_format

    if save_dir:
        basename = osp.basename(audio_file)
        if not osp.isdir(save_dir):
            os.makedirs(save_dir)
        audio_file = osp.join(save_dir, basename)

    if verbose:
        print('===> audio_file saved into: ', audio_file)

    if not osp.isfile(audio_file) or force_overwrite:
        in_stream = ffmpeg.input(video)

        out_stream = ffmpeg.output(in_stream.audio, audio_file)

        if verbose:
            cmdline = ffmpeg.compile(out_stream)
            print('===> ffmpeg cmdline:', cmdline)

        out_stream.run()
    else:
        print('===> audio file already exists at {}, skip'.format(audio_file))

    return audio_file


def extract_audio_and_get_trim_info(video, 
        save_dir='', ext_format='mp3', 
        trim_min_level=0, force_overwrite=False):
    """
    extract_audio_and_get_trim_info

    return:
        trim_info_dict: dict
            a dict with trim info, with structrure like:
            trim_info_dict = {
                'audio_file': audio_file,
                'sample_rate': sample_rate,
                'audo_len': audio_len,
                'duration': duration,
                'max_val': max_val,
                'trim_min_level': trim_min_level,
                'trim_start_idx': start_idx,
                'trim_end_idx': end_idx,
                'trim_start_time': trim_start_time,
                'trim_end_time': trim_end_time,
                'trim_duration': trim_duration
            }
    """
    force_trim = False

    audio_file = extract_audio_into_file(
        video, save_dir, ext_format, force_overwrite)

    if not osp.exists(audio_file) or force_overwrite:
        force_trim = True

    trim_info_dict = get_audio_trim_info(
        audio_file, trim_min_level, force_trim)

    return trim_info_dict


__all__ = ["extract_audio_into_file", 'extract_audio_and_get_trim_info']
