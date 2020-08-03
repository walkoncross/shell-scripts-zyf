#!/bin/bash
## Author: zhaoyafei0210@gmail.com

ffplay $1 -vf "sendcmd=f=test.cmd,drawtext=fontfile=FreeSerif.ttf:text='',hue"

