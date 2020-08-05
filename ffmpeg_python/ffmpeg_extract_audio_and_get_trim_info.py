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

import json


def extract_audio_into_file(video, save_dir='', ext_format='mp3',
                            force_overwrite=False):
    print('===> Video: ', video)
    audio_file = osp.splitext(video)[0]+'.'+ext_format

    if save_dir:
        basename = osp.basename(audio_file)
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


def get_audio_trim_info(audio_file, trim_min_level=0, force_trim=False):
    print('===> audio file: ', audio_file)
    trim_info_json = audio_file+'.trim_info.json'
    print('===> trim_info_json: ', trim_info_json)

    if not osp.isfile(trim_info_json):
        force_trim = True
    elif not force_trim:
        try:
            fp = open(trim_info_json, 'r')
            trim_info_dict = json.load(fp)
            print('===> trim info json already exists, just load')
            fp.close
        except:
            print('===> Failed to load trim info from ',
                  trim_info_json, ' try to re-trim.')
            force_trim = True

    if force_trim:
        audio_data, sample_rate = librosa.load(
            audio_file)  # support .wav/.mp3/.aac files
        # sample_rate, audio_data = wavfile.read(audio_file) # only support .wav files

        if len(audio_data.shape) > 1:
            audio_data = audio_data[:, 0]  # use first audio channel

        print('---> sample rate: ', sample_rate)
        print('---> audio_data.shape: ', audio_data.shape)
        print('---> audio_data.dtype: ', audio_data.dtype)
        print(
            '---> audio trim_duration = {} seconds'.format(audio_data.shape[0] / sample_rate))

        audio_len = audio_data.shape[0]
        max_val = float(audio_data.max())

        print('---> audio_data.max: ', max_val)
        # print('---> type(audio_data.max): ', type(max_val))

        # min_level_val = 0
        min_level_val = max_val * trim_min_level

        for start_idx in range(audio_len):
            if abs(audio_data[start_idx]) > min_level_val:
                print('---> audio_data[start_idx-32:start_idx+32]:',
                      audio_data[start_idx-32:start_idx+32])
                break

        for end_idx in range(audio_len-1, 0, -1):
            if abs(audio_data[end_idx]) > min_level_val:
                print('---> audio_data[end_idx-32:end_idx+32]:',
                      audio_data[end_idx-32:end_idx+32])
                break

        duration = audio_len / sample_rate
        trim_start_time = start_idx/sample_rate
        trim_end_time = end_idx/sample_rate
        trim_duration = trim_end_time - trim_start_time

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

        fp = open(trim_info_json, 'w')
        json.dump(trim_info_dict, fp, indent=2)
        fp.close

    print('---> The first non-zero value is at idx = {}, time= {} seconds'.format(
        trim_info_dict['trim_start_idx'], trim_info_dict['trim_start_time']))
    print('---> The last non-zero value is at idx = {}, time= {} seconds'.format(
        trim_info_dict['trim_end_idx'], trim_info_dict['trim_end_time']))
    print(
        '---> trim_duration of audio is {} seconds'.format(trim_info_dict['trim_duration']))

    print('===> Full trim info: ')
    print(json.dumps(trim_info_dict, indent=2))

    return trim_info_dict


def extract_audio_and_get_trim_info(video, save_dir='', ext_format='mp3', trim_min_level=0, force_overwrite=False):
    force_trim = False

    audio_file = extract_audio_into_file(
        video, save_dir, ext_format, force_overwrite)

    if not osp.exists(audio_file) or force_overwrite:
        force_trim = True

    trim_info_dict = get_audio_trim_info(
        audio_file, trim_min_level, force_trim)

    return trim_info_dict


def _make_argparser():
    parser = argparse.ArgumentParser(
        description='Extract audio channels from video and save into mp3/wav/aac file, '
        'and also return trim infos (trim_start_time, trim_end_time, trim_duration, etc.).')
    parser.add_argument('-f', '--force', '--ow', '--overwrite',
                        type=bool,
                        dest='force_overwrite',
                        default=False,
                        action='store_true',
                        help='Force to overwrite existing audio file and trim info json file.')
    parser.add_argument('-fmt', '--format',
                        type=str,
                        dest='ext_format',
                        default='mp3',
                        help='Extracted audio file extension format, support wav/mp3/aac, default: mp3')
    parser.add_argument('-ml', '--min_level', '--minlevel',
                        dest='trim_min_level',
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

    extract_audio_and_get_trim_info(
        args.video,
        args.save_dir,
        args.ext_format,
        args.trim_min_level,
        args.force_overwrite
    )
