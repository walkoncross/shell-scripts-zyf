#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import argparse
import ffmpeg
import sys
import os
import os.path as osp


def get_video_stream_info(video_filename):
    try:
        probe = ffmpeg.probe(video_filename)
    except ffmpeg.Error as e:
        print(e.stderr, file=sys.stderr)
        sys.exit(1)

    video_stream_info = next(
        (stream for stream in probe['streams'] if stream['codec_type'] == 'video'), None)
    if video_stream_info is None:
        print('No video stream found', file=sys.stderr)
        sys.exit(1)

    return video_stream_info


def stack_two_videos(video1, video2, save_dir='./', vstack=False):
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


def _make_argparser():
    parser = argparse.ArgumentParser(description='stack two videos horizontally (left-right,default)'
                                     'or veritically (top-bottom, if set -vs or --vstack)')
    parser.add_argument('-vs', '--vstack',
                        dest='vstack',
                        action='store_true',
                        default=False,
                        help='If set, stack vertically (top-bottom), else stack horizontally (left-right)')
    parser.add_argument('video1', help='Input filename for the first video')
    parser.add_argument('video2', help='Input filename for the second video')
    parser.add_argument('save_dir', nargs='?', default=os.getcwd(),
                        help='[Optional] Directory to save output video file, default os.getcwd(),'
                        'output filename: {save_dir}/{video1}_and_{video2}_[h/v]stack.mp4')

    return parser


if __name__ == '__main__':
    parser = _make_argparser()
    args = parser.parse_args()

    stack_two_videos(args.video1, args.video2, args.save_dir, args.vstack)
