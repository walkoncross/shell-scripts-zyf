1. 安装：
   1. mac： 
      1. brew install youtube-dl 
      2. 或者：pip install youtube-dl
      3. brew install ffmpeg
   2. linux：
      1. pip install youtube-dl
      2. apt-get install ffmpeg
   3. windows： 
      1. python安装：pip install youtube-dl
      2. 或者直接下载可执行程序：https://youtube-dl.org/downloads/latest/youtube-dl.exe
      3. 从https://www.gyan.dev/ffmpeg/builds/ 下载安装ffmpeg
2. 下载单个视频：

cd downloaded_videos
..\download_video.bat https://www.bilibili.com/video/BV1Fs411v7kF

3. 批量下载视频：
1）将视频url地址逐个保存到url_list.txt，每行一个url;
2)执行下载脚本：
cd downloaded_videos
..\download_url_list.bat ..\url_list.txt