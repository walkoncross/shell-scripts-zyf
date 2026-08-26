# mihomo 无界面代理(替代 Clash Party)

在 macOS 上用纯命令行 mihomo 替代 Clash Party 等 GUI 客户端。
核心进程常驻内存 ~40MB,无 Electron 渲染进程(不再有长时间运行导致的内存泄漏)。

## 安装

```bash
./install-mihomo-headless.sh <订阅URL>
# 或
MIHOMO_SUB_URL=<订阅URL> ./install-mihomo-headless.sh
# 或运行后按提示交互输入订阅 URL
```

脚本会:
1. `brew install mihomo`
2. 生成配置 `/opt/homebrew/etc/mihomo/config.yaml`
   - `proxy-providers` 每日自动拉取订阅(interval: 86400)
   - 分组:`三毛机场`(手动选择)/ `♻️ 自动选择`(自动测速)
3. 下载 zashboard 面板
4. `brew services` 注册开机自启
5. 设置 macOS 系统代理(web/socks → 127.0.0.1:7890)

> 订阅 URL 含 token,属敏感信息,不要写死在脚本/仓库里。

## 日常操作

| 操作 | 方法 |
|---|---|
| 切节点 | 浏览器打开 `http://127.0.0.1:9090/ui/`,输入 secret |
| 立即更新订阅 | `curl -X PUT -H "Authorization: Bearer <secret>" http://127.0.0.1:9090/providers/proxies/三毛机场订阅` |
| 看日志 | `tail -f /opt/homebrew/var/log/mihomo.log` |
| 重启 | `brew services restart mihomo` |
| 停止 | `brew services stop mihomo` |

secret 在 `/opt/homebrew/etc/mihomo/config.yaml` 的 `secret` 字段,由安装脚本随机生成。

## 端口

| 端口 | 用途 |
|---|---|
| 7890 | HTTP + SOCKS 混合(mixed) |
| 7891 | SOCKS |
| 7892 | HTTP |
| 9090 | external-controller API / 面板 |

## 常见问题

- **`bind: address already in use`(mixed-port 7890)**:切换 Clash Party 时旧核心的
  残留连接导致,`brew services restart mihomo` 一次即可(脚本启动前已做端口等待)。
- **`duplicate provider name`**:mihomo 不允许 proxy-group 与 proxy-provider 同名,
  provider 特意命名为「三毛机场订阅」。
- **UI 404**:zashboard 未下载成功,手动装:走代理 `curl -L -x http://127.0.0.1:7890
  -o /tmp/z.zip https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip`,
  解压内容到 `/opt/homebrew/etc/mihomo/ui/`。
- **TUN 模式**:默认关闭,用系统代理;headless 下开 TUN 需要 root 权限,未做。
