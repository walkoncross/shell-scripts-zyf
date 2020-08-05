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

def get_video_stream_info(video_filename):
    try:
        probe = ffmpeg.probe(video_filename)
    except ffmpeg.Error as e:
        print(e.stderr, file=sys.stderr)
        sys.exit(1)

    video_stream = next(
        (stream for stream in probe['streams'] if stream['codec_type'] == 'video'), None)
    if video_stream is None:
        print('No video stream found', file=sys.stderr)
        sys.exit(1)

    return video_stream


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
                # print('---> audio_data[start_idx-32:start_idx+32]:',
                #       audio_data[start_idx-32:start_idx+32])
                break

        for end_idx in range(audio_len-1, 0, -1):
            if abs(audio_data[end_idx]) > min_level_val:
                # print('---> audio_data[end_idx-32:end_idx+32]:',
                #       audio_data[end_idx-32:end_idx+32])
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


def get_audio_align_info(video1, video2, save_dir='./', force_align=False):
    basename1 = osp.splitext(osp.basename(video1))[0]
    basename2 = osp.splitext(osp.basename(video2))[0]

    align_info_json = '{}_and_{}_audio_align_info.json'.format(
        basename1, basename2)
    align_info_json = osp.join(save_dir, align_info_json)

    align_info_dict = dict()

    align_flag = True
    if osp.isfile(align_info_json) and not force_align:
        print('===> align info json already exists at: ', align_info_json)
        print('     try to load')
        try:
            fp = open(align_info_json, 'r')
            align_info_dict = json.load()
            fp.close()
            align_flag = False
        except:
            print('===> failed to load align info json, re-calc align info')

    if align_flag:
        video1_trim_info = extract_audio_and_get_trim_info(video1, save_dir,
                                                           ext_format='mp3',
                                                           trim_min_level=0.01,
                                                           force_overwrite=force_align)
        video2_trim_info = extract_audio_and_get_trim_info(video2, save_dir,
                                                           ext_format='mp3',
                                                           trim_min_level=0.01,
                                                           force_overwrite=force_align)

        trim_start_time1 = video1_trim_info['trim_start_time']
        trim_start_time2 = video2_trim_info['trim_start_time']
        trim_duration1 = video1_trim_info['trim_duration']
        trim_duration2 = video2_trim_info['trim_duration']

        start_time_diff = trim_start_time2 - trim_start_time1
        duration_diff = trim_duration2 - trim_duration1

        trim_margin = 0.1
        time_offset1 = trim_start_time1 - trim_margin
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

        fp = open(align_info_json, 'w')
        json.dump(align_info_dict, fp, indent=2)
        fp.close()

    print('===> align info: ')
    print(json.dumps(align_info_dict, indent=2))

    return align_info_dict


def stack_two_videos_with_audio_alignment(video1, video2,
                                          save_dir='./',
                                          vstack=False,
                                          try_align=True):
    if not save_dir:
        save_dir = os.getcwd()

    if not osp.isdir(save_dir):
        os.makedirs(save_dir)

    basename1 = osp.splitext(osp.basename(video1))[0]
    basename2 = osp.splitext(osp.basename(video2))[0]
    output = '{}_and_{}_{}stack.mp4'.format(
        basename1, basename2, 'v' if vstack else 'h')
    output = osp.join(save_dir, output)

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
    print('width: {}'.format(width2))
    print('height: {}'.format(height2))
    print('num_frames: {}'.format(num_frames_2))

    print('===> Stacked output video: ', output)

    if try_align:
        align_info_dict = get_audio_align_info(video1, video2, save_dir)
        in_stream1 = ffmpeg.input(video1,
                                  ss=align_info_dict['time_offset1'],
                                  t=align_info_dict['time_duration'])
        in_stream2 = ffmpeg.input(video2,
                                  ss=align_info_dict['time_offset2'],
                                  t=align_info_dict['time_duration'])
    else:
        in_stream1 = ffmpeg.input(video1)
        in_stream2 = ffmpeg.input(video2)

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

    out_stream = ffmpeg.output(stacked_video, audio1, output)
    cmdline = ffmpeg.compile(out_stream)
    print('===> ffmpeg cmdline:', cmdline)
    out_stream.run()


def stack_video_list(video_list, save_dir='./', vstack=False, try_align=True):
    n_videos = len(video_list)

    for i in range(n_videos):
        for j in range(i+1, n_videos):
            print('===> stack {} and {}'.format(video_list[i], video_list[j]))
            stack_two_videos_with_audio_alignment(video_list[i], video_list[j],
                                                  save_dir, vstack, try_align)


def stack_video_groups(video_group_list, save_dir='./', vstack=False, try_align=True):
    for group in video_group_list:
        if len(group) > 1:
            print('===> stack group: ', group)
            stack_video_list(group, save_dir, vstack, try_align)


def get_video_groups(input_dir, suffixes=None,
                     group_pattern_delimiter='_'):
    default_video_extensions = ['mp4', 'mov', 'avi', 'mkv']

    if not suffixes:
        suffix_list = default_video_extensions
    elif isinstance(suffixes, str):
        suffix_list = suffixes.split(',')
    elif isinstance(suffixes, list):
        suffix_list = suffixes
    else:
        print('suffixes must be of str or list type')
        exit(1)

    file_list = os.listdir(input_dir)
    print('===> file list: ', file_list)

    tmp_list = list()
    for fn in file_list:
        fn = osp.join(input_dir, fn)
        if not osp.isfile(fn):
            continue

        basename, ext = osp.splitext(fn)
        if not ext:
            continue

        if ext[1:] not in suffix_list:
            continue

        group_name = basename.split(group_pattern_delimiter)[0]

        tmp_list.append(dict(fn=fn, gn=group_name))

    print('===> video file list: ', tmp_list)

    group_dict = dict()
    for item in tmp_list:
        if item['gn'] not in group_dict:
            group_dict[item['gn']] = [item['fn']]
        else:
            group_dict[item['gn']].append(item['fn'])

    print('===> video groups: ', group_dict)

    group_list = list(group_dict.values())

    return group_list


def list_and_stack_video_groups(input_dir, save_dir='', suffixes='',
                                group_pattern_delimiter='_', vstack=False, try_align=True):
    group_list = get_video_groups(
        input_dir, suffixes,
        group_pattern_delimiter
    )
    print('===> group list: ', group_list)
    stack_video_groups(group_list, save_dir, vstack, try_align)


def _make_argparser():
    input_dir = './'
    save_dir = osp.join(input_dir + 'stacked_videos')
    parser = argparse.ArgumentParser(description='stack two videos horizontally (left-right,default)'
                                     'or veritically (top-bottom, if set -vs or --vstack)')
    parser.add_argument('-vs', '--vstack',
                        dest='vstack',
                        action='store_true',
                        default=False,
                        help='If set, stack vertically (top-bottom), else stack horizontally (left-right)')
    parser.add_argument('-na', '--no_align',
                        dest='try_align',
                        action='store_false',
                        default=True,
                        help='Do not align audio')
    parser.add_argument('-s', '--suffixes', '--video_suffixes',
                        dest='suffixes',
                        default='mp4,mov,avi,mkv',
                        help='Video extension suffixes, default: "mp4,mov,avi,mkv"')
    parser.add_argument('-d', '--delimiter',
                        dest='delimiter',
                        default='_',
                        help='Group pattern delimiter, video filenames should have pattern:'
                                ' {group_name}{delimiter}{index}.{suffix}')
    parser.add_argument('input_dir',
                        nargs='?',
                        default=input_dir,
                        help='[Optional] Input dir to glob video files, default: '+input_dir)
    parser.add_argument('save_dir',
                        nargs='?',
                        default=save_dir,
                        help='[Optional] Directory to save output video file, default: ' + save_dir +
                        ', output filename: {save_dir}/{video1}_and_{video2}_[h/v]stack.mp4')

    return parser


if __name__ == '__main__':
    parser = _make_argparser()
    args = parser.parse_args()
    print('===> args: ', args)
    list_and_stack_video_groups(
        args.input_dir,
        args.save_dir,
        args.suffixes,
        args.delimiter,
        args.vstack,
        args.try_align)
