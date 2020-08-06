#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import os
import os.path as osp
import sys
import json
import argparse


TEST_DIR = osp.dirname(__file__)
print('===> TEST_DIR: ', TEST_DIR)
sys.path.append(osp.dirname(TEST_DIR))

from ffmpeg_python_tools import get_align_offsets, extract_audio_and_get_trim_info


def get_video_align_info(
        video1, video2,
        save_dir='./',
        trim_min_level=0.01,
        force_trim=False,
        verbose=0):
    """
    Get align timeoffsets for two videos.

    return:
        align_info_dict: dict 
            a dict of time offsets infos, in the format of:
            {
                "time_offset1": time_offset1,
                "time_offset2": time_offset1,
                "time_duration": time_duration,
            }
    """
    if not osp.exists(save_dir):
        os.makedirs(save_dir)

    rootname1 = osp.splitext(video1)[0]
    rootname2 = osp.splitext(video2)[0]

    trim_info_json1 = rootname1 + '.trim_info.json'
    trim_info_json2 = rootname2 + '.trim_info.json'

    align_info_json = '{}_and_{}.align_info.json'.format(
        osp.basename(rootname1), osp.basename(rootname2))
    align_info_json = osp.join(save_dir, align_info_json)

    align_info_dict = dict()

    if not osp.isfile(trim_info_json1) or force_trim:
        video1_trim_info = extract_audio_and_get_trim_info(
            video1, save_dir,
            ext_format='mp3',
            trim_min_level=trim_min_level,
            force_overwrite=True)

        if verbose:
            print('===> save trim info into: ', trim_info_json1)

        fp = open(trim_info_json1, 'w')
        json.dump(video1_trim_info, fp, indent=2)
        fp.close()
    else:
        if verbose:
            print('===> load trim info from: ', trim_info_json1)

        fp = open(trim_info_json1, 'r')
        video1_trim_info = json.load(fp)
        fp.close()

    if verbose:
        print('===> trim info: ', json.dumps(video1_trim_info, indent=2))

    if not osp.isfile(trim_info_json2) or force_trim:
        video2_trim_info = extract_audio_and_get_trim_info(
            video2, save_dir,
            ext_format='mp3',
            trim_min_level=trim_min_level,
            force_overwrite=True)

        if verbose:
            print('===> save trim info into: ', trim_info_json2)

        fp = open(trim_info_json2, 'w')
        json.dump(video2_trim_info, fp, indent=2)
        fp.close()
    else:
        if verbose:
            print('===> load trim info from: ', trim_info_json2)

        fp = open(trim_info_json2, 'r')
        video2_trim_info = json.load(fp)
        fp.close()

    if verbose:
        print('===> trim info: ', json.dumps(video2_trim_info, indent=2))

    align_info_dict = get_align_offsets(
        video1_trim_info['trim_start_time'], video1_trim_info['trim_end_time'],
        video2_trim_info['trim_start_time'], video2_trim_info['trim_end_time'],
        verbose=verbose
    )

    if verbose:
        print('===> align info: ')
        print(json.dumps(align_info_dict, indent=2))

    if verbose:
        print('===> save align info into: ', align_info_json)

    fp = open(align_info_json, 'w')
    json.dump(align_info_json, fp, indent=2)
    fp.close()

    return align_info_dict


def _make_argparser():
    parser = argparse.ArgumentParser(
        description='Get video/audio alignment infos (time_offset1, time_offset2, time_duration).')
    parser.add_argument('-f', '--force', '--ow', '--overwrite',
                        dest='force_overwrite',
                        default=False,
                        action='store_true',
                        help='Force to overwrite existing audio file and trim info json file.')
    parser.add_argument('-ml', '--min_level', '--minlevel',
                        dest='trim_min_level',
                        type=float,
                        default=0,
                        help='Min level (ratio to the max value of the audio data sequence) '
                        'to trim from both the beginning and from the end, default: 0.0')
    parser.add_argument('input1', help='the first input audio/video file')
    parser.add_argument('input2', help='the second input audio/video file')
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

    get_video_align_info(
        args.input1,
        args.input2,
        args.save_dir,
        args.trim_min_level,
        force_trim=args.force_overwrite,
        verbose=True
    )
