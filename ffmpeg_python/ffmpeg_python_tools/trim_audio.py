#!/usr/bin/env python
# Author: zhaoyafei0210@gmail.com

from __future__ import unicode_literals, print_function
import os
import os.path as osp

# from scipy.io import wavfile
import librosa

import json


def get_audio_trim_info(
        audio_file,
        trim_min_level=0,
        force_trim=False,
        verbose=False):
    """
    Get audio trim info (trim_start_time, trim_end_time) using a threshold `trim_min_level` (ration to the max value of audio data).

    @params:
        audio_file: str
            path of input audio file
        trim_min_level: float
            a threshold `trim_min_level` (ration to the max value of audio data)
        force_trim: bool
            If False, try to firstly load available trim info json files.
            If True, calc trim_info_dict. 
        verbose: bool
            Print verbose information, mainly for debug.

    @return:
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
    trim_info_json = osp.splitext(audio_file)[0]+'.trim_info.json'

    if verbose:
        print('===> input audio file: ', audio_file)
        print('===> trim_info_json: ', trim_info_json)

    if not osp.isfile(trim_info_json):
        force_trim = True
    elif not force_trim:
        try:
            fp = open(trim_info_json, 'r')
            trim_info_dict = json.load(fp)
            print('===> trim info json already exists at {}. \nJust load'.format(
                trim_info_json))
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

        if verbose:
            print('---> sample rate: ', sample_rate)
            print('---> audio_data.shape: ', audio_data.shape)
            print('---> audio_data.dtype: ', audio_data.dtype)
            print(
                '---> audio trim_duration = {} seconds'.format(audio_data.shape[0] / sample_rate))

        audio_len = audio_data.shape[0]
        max_val = float(audio_data.max())

        # min_level_val = 0
        min_level_val = max_val * trim_min_level

        if verbose:
            print('---> audio_data.max: ', max_val)
            # print('---> type(audio_data.max): ', type(max_val))
            print('---> trim_min_level: ', trim_min_level)
            print('---> min_level_val: ', min_level_val)

        for start_idx in range(audio_len):
            if abs(audio_data[start_idx]) > min_level_val:
                if verbose == 2:
                    print('---> audio_data[start_idx-32:start_idx+32]:',
                          audio_data[start_idx-32:start_idx+32])
                break

        for end_idx in range(audio_len-1, 0, -1):
            if abs(audio_data[end_idx]) > min_level_val:
                if verbose == 2:
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

    if verbose:
        print('===>The first non-zero value is at idx = {}, time= {} seconds'.format(
            trim_info_dict['trim_start_idx'], trim_info_dict['trim_start_time']))
        print('===> The last non-zero value is at idx = {}, time= {} seconds'.format(
            trim_info_dict['trim_end_idx'], trim_info_dict['trim_end_time']))
        print(
            '===> trim_duration of audio is {} seconds'.format(trim_info_dict['trim_duration']))

        print('===> Full trim info: ')
        print(json.dumps(trim_info_dict, indent=2))

    return trim_info_dict


__all__ = ["get_audio_trim_info"]
