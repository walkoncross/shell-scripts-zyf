# 在不同机器之间同步文件

zhaoyafei0210@gmail.com


## 两台Mac上同步文件夹

### 使用 rsync 命令（终端同步）-- by Deepseek

#### 适用场景：
需要精确控制同步，支持增量备份。
#### 步骤：

1. 打开终端（Terminal），使用 rsync 命令同步文件夹。例如：
    ```bash
    rsync -avz --progress /path/to/source/folder username@另一台Mac的IP:/path/to/destination/folder
    ```
    参数说明：
    - -avz：归档模式、保留属性、压缩传输。
    - --progress：显示进度。

2. 需确保：
    - 另一台 Mac 已开启“远程登录”（系统设置 > 通用 > 共享 > 远程登录）。

    - 替换 username 和 IP 为实际值（IP 可通过另一台 Mac 的 系统设置 > 网络 查看）。

#### 自动化：
可将命令保存为脚本，结合 cron 或 launchd 定时执行。
