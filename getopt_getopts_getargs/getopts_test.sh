#!/bin/bash

verbose=0
output_file=""

# 解析选项: v(无参数), o(有参数)
while getopts "vo:" opt; do
    case $opt in
        v)
            verbose=1
            echo "详细模式已开启"
            ;;
        o)
            output_file="$OPTARG"
            echo "输出文件设置为: $output_file"
            ;;
        \?)
            echo "无效选项: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "选项 -$OPTARG 需要参数" >&2
            exit 1
            ;;
    esac
done

# 移除已处理的选项，剩下的是位置参数
shift $((OPTIND - 1))

echo "剩余参数: $@"
echo "参数数量: $#"
echo "详细模式: $verbose"
echo "输出文件: $output_file"