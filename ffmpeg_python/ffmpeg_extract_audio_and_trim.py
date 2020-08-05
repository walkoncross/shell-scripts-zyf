#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import argparse
import sys
import os
import os.path as osp

import ffmpeg
# from scipy.io import wavfile
import librosa


def extract_audio_and_get_trim_timestamp(video, save_dir='', ext_format='mp3', min_level=0):
    print('===> Video: ', video)
    output = osp.splitext(video)[0]+'.'+ext_format
    if save_dir:
        basename = osp.basename(output)
        if not osp.isdir(save_dir):
            os.makedirs(save_dir)
        output = osp.join(save_dir, basename)

    print('===> output audio file: ', output)

    if not osp.exists(output):
        in_stream = ffmpeg.input(video)
        out_stream = ffmpeg.output(in_stream.audio, output)

        cmdline = ffmpeg.compile(out_stream)
        print('===> ffmpeg cmdline:', cmdline)

        out_stream.run()

    audio_data, sample_rate = librosa.load(output)
    # sample_rate, audio_data = wavfile.read(output)

    if len(audio_data.shape) > 1:
        audio_data = audio_data[:, 0]  # use first audio channel

    print('---> sample rate: ', sample_rate)
    print('---> audio_data.shape: ', audio_data.shape)
    print('---> audio_data.dtype: ', audio_data.dtype)
    print(
        '---> audio duration = {} seconds'.format(audio_data.shape[0] / sample_rate))

    audio_len = audio_data.shape[0]

    print('---> audio_data.max: ', audio_data.max())

    # min_level = 0
    min_level = audio_data.max() * min_level

    for start_idx in range(audio_len):
        if abs(audio_data[start_idx]) > min_level:
            print('---> audio_data[start_idx-32:start_idx+32]:',
                  audio_data[start_idx-32:start_idx+32])
            break

    for end_idx in range(audio_len-1, 0, -1):
        if abs(audio_data[end_idx]) > min_level:
            print('---> audio_data[end_idx-32:end_idx+32]:',
                  audio_data[end_idx-32:end_idx+32])
            break

    start_time = start_idx/sample_rate
    end_time = end_idx/sample_rate
    duration = end_time - start_time

    print('---> The first non-zero value is at idx = {}, time= {} seconds'.format(
        start_idx, start_time))
    print('---> The last non-zero value is at idx = {}, time= {} seconds'.format(end_idx, end_time))
    print('---> Effective duration of audio is {} seconds'.format(duration))

    return (start_time, end_time, duration)


def _make_argparser():
    parser = argparse.ArgumentParser(
        description='Extract audio channels from video and save into mp3/wav/aac file, '
        'and also return trim timestamps (start_time, end_time, duration).')
    parser.add_argument('-f', '-fmt', '--format',
                        type=str,
                        dest='ext_format',
                        default='mp3',
                        help='Extracted audio file extension format, support wav/mp3/aac, default: mp3')
    parser.add_argument('-ml', '--minlevel',
                        dest='min_level',
                        type=float,
                        default=0,
                        help='Min level (ratio to the max value of the audio data sequence) '
                        'to trim from both the beginning and from the end, default: 0.0')
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

    extract_audio_and_get_trim_timestamp(
        args.video, args.save_dir, args.ext_format, args.min_level)
