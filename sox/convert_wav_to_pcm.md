# 语音文件格式转换 - .wav格式转.au格式(.pcm)

- [语音文件格式转换 - .wav格式转.au格式(.pcm)](#语音文件格式转换---wav格式转au格式pcm)
  - [1. 安装sox](#1-安装sox)
  - [2. 执行转换命令](#2-执行转换命令)
  - [3. 查看音频文件信息](#3-查看音频文件信息)
- [zhaoyafei @ JamesZhaodeMacBook-Pro in ~/Downloads [18:09:08]](#zhaoyafei--jameszhaodemacbook-pro-in-downloads-180908)
- [zhaoyafei @ JamesZhaodeMacBook-Pro in ~/Downloads [18:09:13]](#zhaoyafei--jameszhaodemacbook-pro-in-downloads-180913)

##  1. 安装sox
mac os上： brew install sox
linux上：apt-get install sox

## 2. 执行转换命令

在命令行里执行命令：
"sox input_file -t au -r 44100 -b 16 -c 1 output_file"
例如：
sox i-zyf.wav -t au -r 44100 -b 16 -c 1 i-zyf.pcm

## 3. 查看音频文件信息
a) 输入文件信息：
$ soxi i-zyf.wav

Input File : 'i-zyf.wav'
Channels : 1
Sample Rate : 44100
Precision : 16-bit
Duration : 00:00:02.82 = 124352 samples = 211.483 CDDA sectors
File Size : 249k
Bit Rate : 706k
Sample Encoding: 16-bit Signed Integer PCM

b) sox转换之后的文件信息：
# zhaoyafei @ JamesZhaodeMacBook-Pro in ~/Downloads [18:09:08]
$ soxi i-zyf.pcm

Input File : 'i-zyf.pcm' (au)
Channels : 1
Sample Rate : 44100
Precision : 16-bit
Duration : 00:00:02.82 = 124352 samples = 211.483 CDDA sectors
File Size : 249k
Bit Rate : 706k
Sample Encoding: 16-bit Signed Integer PCM
Comment : 'Processed by SoX'

c) adobe audition转换之后的文件信息

(作为对比验证，说明sox转换的文件格式无误)


# zhaoyafei @ JamesZhaodeMacBook-Pro in ~/Downloads [18:09:13]
$ soxi i-zyf.au
soxi WARN au: header size 24 is too small

Input File : 'i-zyf.au'
Channels : 1
Sample Rate : 44100
Precision : 16-bit
Duration : 00:00:02.82 = 124352 samples = 211.483 CDDA sectors
File Size : 249k
Bit Rate : 706k
Sample Encoding: 16-bit Signed Integer PCM