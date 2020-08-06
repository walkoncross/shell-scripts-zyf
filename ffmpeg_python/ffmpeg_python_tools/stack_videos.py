#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import argparse
import sys
import os
import os.path as osp
import glob

import ffmpeg
import librosa
import json

from .stream_info import get_video_stream_info
from .utils import join_two_filenames

def stack_two_videos(video1, video2,
                     save_dir='./',
                     vstack=False,
                     time_offset1=0,
                     time_offset2=0,
                     time_duration=0,
                     verbose=0):
    """
    stack two videos.

    return:
        output_path: str
            path to output video file.
    """
    if not save_dir:
        save_dir = os.getcwd()

    if not osp.isdir(save_dir):
        os.makedirs(save_dir)

    joined_name = join_two_filenames(video1, video2, '_and_')
    output_path = '{}_{}stack.mp4'.format( joined_name, 'v' if vstack else 'h')
    output_path = osp.join(save_dir, output_path)

    print('===> Video1: ', video1)

    video1_info = get_video_stream_info(video1)

    width1 = int(video1_info['width'])
    height1 = int(video1_info['height'])
    num_frames_1 = int(video1_info['nb_frames'])

    print('width: {}'.format(width1))
    print('height: {}'.format(height1))
    print('num_frames: {}'.format(num_frames_1))

    print('===> Video2: ', video2)

    video2_info = get_video_stream_info(video2)

    width2 = int(video2_info['width'])
    height2 = int(video2_info['height'])
    num_frames_2 = int(video2_info['nb_frames'])
    if verbose:
        print('width: {}'.format(width2))
        print('height: {}'.format(height2))
        print('num_frames: {}'.format(num_frames_2))

    print('===> Stacked output_path video: ', output_path)

    if time_duration > 0:
        in_stream1 = ffmpeg.input(video1,
                                  ss=time_offset1,
                                  t=time_duration)
        in_stream2 = ffmpeg.input(video2,
                                  ss=time_offset2,
                                  t=time_duration)
    else:
        in_stream1 = ffmpeg.input(video1, ss=time_offset1)
        in_stream2 = ffmpeg.input(video2, ss=time_offset2)

    video1 = in_stream1.video
    audio1 = in_stream1.audio
    video2 = in_stream2.video
    # audio2 = in_stream2.audio

    if vstack:
        if width1 == width2:
            print(
                '---> The two videos has the same width, simply stack video1 and video2.')
            stacked_video = ffmpeg.filter((video1, video2), 'vstack')
        else:
            print('---> The two videos has different widths, resize video2 to have the same width as video2,'
                  ' and then stack video1 and resize video2.')
            video2_resized = video2.filter('scale', w=str(width1), h='-2')

            stacked_video = ffmpeg.filter((video1, video2_resized), 'vstack')
    else:
        if height1 == height2:
            print(
                '---> The two videos has the same height, simply stack video1 and video2')
            stacked_video = ffmpeg.filter((video1, video2), 'hstack')
        else:
            print('---> The two videos has different height, resize video2 to have the same height as video2,'
                  ' and then stack video1 and resize video2.')

            video2_resized = video2.filter('scale', w='-2', h=str(height1))

            stacked_video = ffmpeg.filter((video1, video2_resized), 'hstack')

    out_stream = ffmpeg.output(stacked_video, audio1, output_path)

    if verbose:
        cmdline = ffmpeg.compile(out_stream)
        print('===> ffmpeg cmdline:', cmdline)

    out_stream.run()

    return output_path


__all__=['stack_two_videos']