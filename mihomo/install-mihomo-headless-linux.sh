#!/bin/bash
# ============================================================
# Linux 版:安装并配置无界面(纯命令行)mihomo 代理
# 与 macOS 版(install-mihomo-headless.sh)配置互通,差异仅在:
#   - 下载 GitHub 预编译二进制(含国内镜像回退)
#   - systemd 服务代替 brew services,以 root 运行(config 放 /etc/mihomo)
#   - TUN 全局代理可选(默认关闭,用系统代理/环境变量)
#
# 用法(需要 root):
#   sudo ./install-mihomo-headless-linux.sh [订阅URL]
#   MIHOMO_SUB_URL=<订阅URL> sudo -E ./install-mihomo-headless-linux.sh
#   ENABLE_TUN=1 时启用 TUN 全局代理(默认 0=关)
#   MIHOMO_VERSION 可覆盖版本号(默认 1.19.30)
#
# 注意:订阅 URL 含 token,属敏感信息,勿写死在本脚本中
# ============================================================
set -e

# ---------- 0. 需要 root(写 /usr/local/bin、/etc/mihomo、systemd) ----------
if [ "$(id -u)" -ne 0 ]; then
  echo "错误:请用 sudo 运行本脚本"
  exit 1
fi

# ---------- 1. 订阅 URL(参数 > 环境变量 > 交互输入) ----------
SUB_URL="${1:-$MIHOMO_SUB_URL}"
if [ -z "$SUB_URL" ]; then
  read -rp "请输入机场订阅 URL: " SUB_URL
fi
[ -z "$SUB_URL" ] && { echo "错误:未提供订阅 URL"; exit 1; }

# ---------- 2. 常量 ----------
MIHOMO_VERSION="${MIHOMO_VERSION:-1.19.30}"
CFG_DIR="${CFG_DIR:-/etc/mihomo}"
BACKUP_DIR="${BACKUP_DIR:-/root/claude-temp}"
ENABLE_TUN="${ENABLE_TUN:-0}"
MIXED_PORT=7890          # HTTP+SOCKS 混合端口
SOCKS_PORT=7891          # SOCKS 独立端口
HTTP_PORT=7892           # HTTP 独立端口
CTRL_PORT=9090           # external-controller(API/面板)

# ---------- 3. 架构识别 ----------
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)  BIN_ARCH="amd64" ;;
  aarch64|arm64) BIN_ARCH="arm64" ;;
  *) echo "错误:不支持的架构 $ARCH(可用 amd64/arm64,旧 CPU 可换 -compatible 包)"
     exit 1 ;;
esac

# ---------- 4. 安装二进制(直连失败自动回退 ghfast 镜像) ----------
if ! command -v mihomo >/dev/null 2>&1; then
  TMP_BIN=/tmp/mihomo-${MIHOMO_VERSION}
  BIN_URL="https://github.com/MetaCubeX/mihomo/releases/download/v${MIHOMO_VERSION}/mihomo-linux-${BIN_ARCH}-v${MIHOMO_VERSION}.gz"
  echo ">> 下载 mihomo ${MIHOMO_VERSION} (${BIN_ARCH}) ..."
  if ! (curl -fsSL -o "$TMP_BIN.gz" "$BIN_URL" || \
        curl -fsSL -o "$TMP_BIN.gz" "https://ghfast.top/$BIN_URL" || \
        wget -qO "$TMP_BIN.gz" "https://ghfast.top/$BIN_URL"); then
    echo "错误:下载失败,请检查网络或换 MIHOMO_VERSION"
    exit 1
  fi
  gunzip -f "$TMP_BIN.gz"
  install -m 755 "$TMP_BIN" /usr/local/bin/mihomo
  echo ">> mihomo 已装到 /usr/local/bin/mihomo"
fi
MIHOMO_BIN="$(command -v mihomo)"

# ---------- 5. 生成随机 API 密钥(见 config.yaml 的 secret) ----------
if command -v openssl >/dev/null 2>&1; then
  SECRET="$(openssl rand -hex 16)"
elif command -v xxd >/dev/null 2>&1; then
  SECRET="$(head -c 16 /dev/urandom | xxd -p -c 32)"
else
  SECRET="$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')"
fi

# ---------- 6. 备份旧配置 ----------
if [ -f "$CFG_DIR/config.yaml" ]; then
  mkdir -p "$BACKUP_DIR"
  cp "$CFG_DIR/config.yaml" "$BACKUP_DIR/mihomo-config-backup-$(date +%Y%m%d-%H%M%S).yaml"
  echo ">> 旧配置已备份到 $BACKUP_DIR/"
fi
mkdir -p "$CFG_DIR"

TUN_ENABLE="false"
[ "$ENABLE_TUN" = "1" ] && TUN_ENABLE="true"

# ---------- 7. 写入配置(与 macOS 版一致,仅 tun 按需开关) ----------
cat > "$CFG_DIR/config.yaml" <<EOF
mixed-port: ${MIXED_PORT}
allow-lan: false
bind-address: "*"
external-controller: 127.0.0.1:${CTRL_PORT}
secret: ${SECRET}
external-ui: ui
external-ui-url: https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip
mode: rule
log-level: info
unified-delay: true
tcp-concurrent: false
geox-url:
  geoip: https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip-lite.dat
  geosite: https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat
  mmdb: https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.metadb
  asn: https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/GeoLite2-ASN.mmdb
dns:
  enable: true
  ipv6: false
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  use-hosts: false
  default-nameserver:
    - tls://223.5.5.5
  nameserver:
    - https://120.53.53.53/dns-query
    - https://223.5.5.5/dns-query
  proxy-server-nameserver:
    - https://120.53.53.53/dns-query
    - https://223.5.5.5/dns-query
  fake-ip-filter:
    - "*"
    - +.lan
    - +.local
    - time.*.com
    - ntp.*.com
    - +.market.xiaomi.com
  use-system-hosts: false
  respect-rules: false
  direct-nameserver: []
  fallback: []
  fallback-filter:
    geoip: true
    geoip-code: CN
    ipcidr:
      - 240.0.0.0/4
      - 0.0.0.0/32
    domain:
      - +.google.com
      - +.facebook.com
      - +.youtube.com
proxy-providers:
  三毛机场订阅:
    type: http
    url: ${SUB_URL}
    interval: 86400
    path: ./providers/airport.yaml
    health-check:
      enable: true
      url: https://www.gstatic.com/generate_204
      interval: 300
proxies: []
proxy-groups:
  - name: ♻️ 自动选择
    type: url-test
    use:
      - 三毛机场订阅
    url: http://www.apple.com/library/test/success.html
    interval: 300
  - name: 三毛机场
    type: select
    proxies:
      - ♻️ 自动选择
    use:
      - 三毛机场订阅
rules:
  - DOMAIN-SUFFIX,caijj.net,DIRECT
  - IP-CIDR,119.45.113.238/8,DIRECT,no-resolve
  - DOMAIN,modelscope.cn,DIRECT
  - DOMAIN,z.ai,DIRECT
  - DOMAIN,aliyun.com,DIRECT
  - DOMAIN-SUFFIX,weheretech.cn,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT,no-resolve
  - IP-CIDR,10.0.0.0/8,DIRECT,no-resolve
  - IP-CIDR,172.16.0.0/12,DIRECT,no-resolve
  - DOMAIN-SUFFIX,modelscope.cn,DIRECT
  - DOMAIN,api.ip.sb,REJECT
  - DOMAIN,ipapi.co,REJECT
  - DOMAIN,api.ipapi.is,REJECT
  - DOMAIN,ipwho.is,REJECT
  - DOMAIN,injections.adguard.org,DIRECT
  - DOMAIN,local.adguard.org,DIRECT
  - IP-CIDR,0.0.0.0/8,DIRECT,no-resolve
  - IP-CIDR,10.0.0.0/8,DIRECT,no-resolve
  - IP-CIDR,100.64.0.0/10,DIRECT,no-resolve
  - IP-CIDR,127.0.0.0/8,DIRECT,no-resolve
  - IP-CIDR,169.254.0.0/16,DIRECT,no-resolve
  - IP-CIDR,172.16.0.0/12,DIRECT,no-resolve
  - IP-CIDR,192.0.0.0/24,DIRECT,no-resolve
  - IP-CIDR,192.0.2.0/24,DIRECT,no-resolve
  - IP-CIDR,192.88.99.0/24,DIRECT,no-resolve
  - IP-CIDR,192.168.0.0/16,DIRECT,no-resolve
  - IP-CIDR,198.18.0.0/15,DIRECT,no-resolve
  - IP-CIDR,198.51.100.0/24,DIRECT,no-resolve
  - IP-CIDR,203.0.113.0/24,DIRECT,no-resolve
  - IP-CIDR,224.0.0.0/3,DIRECT,no-resolve
  - IP-CIDR,::/127,DIRECT,no-resolve
  - IP-CIDR,fc00::/7,DIRECT,no-resolve
  - IP-CIDR,fe80::/10,DIRECT,no-resolve
  - IP-CIDR,ff00::/8,DIRECT,no-resolve
  - RULE-SET,private_domain,DIRECT,no-resolve
  - IP-CIDR,5.28.195.0/24,REJECT,no-resolve
  - DOMAIN,safebrowsing.urlsec.qq.com,DIRECT
  - DOMAIN,safebrowsing.googleapis.com,DIRECT
  - DOMAIN,developer.apple.com,三毛机场
  - DOMAIN-SUFFIX,digicert.com,三毛机场
  - DOMAIN,ocsp.apple.com,三毛机场
  - DOMAIN,ocsp.comodoca.com,三毛机场
  - DOMAIN,ocsp.usertrust.com,三毛机场
  - DOMAIN,ocsp.sectigo.com,三毛机场
  - DOMAIN,ocsp.verisign.net,三毛机场
  - DOMAIN-SUFFIX,apple-dns.net,三毛机场
  - DOMAIN,testflight.apple.com,三毛机场
  - DOMAIN,sandbox.itunes.apple.com,三毛机场
  - DOMAIN,itunes.apple.com,三毛机场
  - DOMAIN-SUFFIX,apps.apple.com,三毛机场
  - DOMAIN-SUFFIX,blobstore.apple.com,三毛机场
  - DOMAIN,cvws.icloud-content.com,三毛机场
  - DOMAIN-SUFFIX,mzstatic.com,DIRECT
  - DOMAIN-SUFFIX,itunes.apple.com,DIRECT
  - DOMAIN-SUFFIX,icloud.com,DIRECT
  - DOMAIN-SUFFIX,icloud-content.com,DIRECT
  - DOMAIN-SUFFIX,me.com,DIRECT
  - DOMAIN-SUFFIX,aaplimg.com,DIRECT
  - DOMAIN-SUFFIX,cdn20.com,DIRECT
  - DOMAIN-SUFFIX,cdn-apple.com,DIRECT
  - DOMAIN-SUFFIX,akadns.net,DIRECT
  - DOMAIN-SUFFIX,akamaiedge.net,DIRECT
  - DOMAIN-SUFFIX,edgekey.net,DIRECT
  - DOMAIN-SUFFIX,mwcloudcdn.com,DIRECT
  - DOMAIN-SUFFIX,mwcname.com,DIRECT
  - DOMAIN-SUFFIX,apple.com,DIRECT
  - DOMAIN-SUFFIX,apple-cloudkit.com,DIRECT
  - DOMAIN-SUFFIX,apple-mapkit.com,DIRECT
  - AND,((DST-PORT,443),(NETWORK,UDP)),REJECT
  - DOMAIN-SUFFIX,services.googleapis.cn,三毛机场
  - DOMAIN-SUFFIX,xn--ngstr-lra8j.com,三毛机场
  - RULE-SET,geolocation-!cn,三毛机场,no-resolve
  - RULE-SET,cn_domain,DIRECT,no-resolve
  - IP-CIDR,221.228.32.13/32,三毛机场
  - RULE-SET,cn_ip,DIRECT
  - MATCH,三毛机场
rule-anchor:
  ip:
    type: http
    interval: 86400
    behavior: ipcidr
    format: mrs
  domain:
    type: http
    interval: 86400
    behavior: domain
    format: mrs
rule-providers:
  private_domain:
    type: http
    interval: 86400
    behavior: domain
    format: mrs
    url: https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/private.mrs
  cn_domain:
    type: http
    interval: 86400
    behavior: domain
    format: mrs
    url: https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/cn.mrs
  geolocation-!cn:
    type: http
    interval: 86400
    behavior: domain
    format: mrs
    url: https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/geolocation-!cn.mrs
  cn_ip:
    type: http
    interval: 86400
    behavior: ipcidr
    format: mrs
    url: https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/cn.mrs
ipv6: true
socks-port: ${SOCKS_PORT}
port: ${HTTP_PORT}
redir-port: 0
tproxy-port: 0
find-process-mode: strict
lan-allowed-ips:
  - 0.0.0.0/0
  - ::/0
lan-disallowed-ips: []
authentication: []
skip-auth-prefixes:
  - 127.0.0.1/32
  - ::1/128
tun:
  enable: ${TUN_ENABLE}
  stack: mixed
  auto-route: true
  auto-redirect: false
  auto-detect-interface: true
  dns-hijack:
    - any:53
  route-exclude-address: []
  mtu: 1500
  device: utun1500
sniffer:
  enable: true
  parse-pure-ip: true
  force-dns-mapping: true
  override-destination: false
  sniff:
    HTTP:
      ports:
        - 80
        - 443
      override-destination: false
    TLS:
      ports:
        - 443
  skip-domain:
    - +.push.apple.com
  skip-dst-address:
    - 91.105.192.0/23
    - 91.108.4.0/22
    - 91.108.8.0/21
    - 91.108.16.0/21
    - 91.108.56.0/22
    - 95.161.64.0/20
    - 149.154.160.0/20
    - 185.76.151.0/24
    - 2001:67c:4e8::/48
    - 2001:b28:f23c::/47
    - 2001:b28:f23f::/48
    - 2a0a:f280:203::/48
profile:
  store-selected: true
  store-fake-ip: true
geo-auto-update: false
geo-update-interval: 24
geodata-mode: false
EOF
echo ">> 配置已写入 $CFG_DIR/config.yaml (secret 在文件里, TUN=$TUN_ENABLE)"

# ---------- 8. 校验配置 ----------
echo ">> 校验配置 ..."
"$MIHOMO_BIN" -t -d "$CFG_DIR" >/dev/null 2>&1 || {
  echo "配置校验失败:"
  "$MIHOMO_BIN" -t -d "$CFG_DIR"
  exit 1
}

# ---------- 9. systemd 服务(开机自启) ----------
cat > /etc/systemd/system/mihomo.service <<EOF
[Unit]
Description=mihomo proxy (headless)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${MIHOMO_BIN} -d ${CFG_DIR}
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable mihomo >/dev/null 2>&1
systemctl restart mihomo
echo ">> systemd 服务已启动并开机自启"

# 等待端口就绪
for _ in $(seq 1 15); do
  ss -tlnp 2>/dev/null | grep -q ":$MIXED_PORT " && break
  sleep 1
done

# ---------- 10. 下载 zashboard 面板(走刚启动的代理,失败不影响代理) ----------
mkdir -p "$CFG_DIR/ui"
curl -fsSL -x "http://127.0.0.1:${MIXED_PORT}" -o /tmp/mihomo-zashboard.zip \
  https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip || true
if [ -s /tmp/mihomo-zashboard.zip ]; then
  unzip -o -q /tmp/mihomo-zashboard.zip -d "$CFG_DIR/ui" || true
  if [ -d "$CFG_DIR/ui/dist" ]; then
    mv "$CFG_DIR/ui/dist"/* "$CFG_DIR/ui/"
    rmdir "$CFG_DIR/ui/dist"
  fi
  mv -f /tmp/mihomo-zashboard.zip "$BACKUP_DIR/mihomo-zashboard.zip"
  echo ">> zashboard 面板已装: http://127.0.0.1:${CTRL_PORT}/ui/"
else
  echo "!! 面板下载失败(可稍后手动补装),不影响代理使用"
fi

# ---------- 11. 验证 ----------
echo ">> 验证代理连通 ..."
curl -s -o /dev/null -w "   HTTP %{http_code} in %{time_total}s\n" \
  -x "http://127.0.0.1:${MIXED_PORT}" https://www.gstatic.com/generate_204 --max-time 20

echo
echo "=== 完成 ==="
echo "切节点:   浏览器打开 http://127.0.0.1:${CTRL_PORT}/ui/ 输入密钥"
echo "手动更新: curl -X PUT -H 'Authorization: Bearer <secret>' http://127.0.0.1:${CTRL_PORT}/providers/proxies/三毛机场订阅"
echo "查日志:   journalctl -u mihomo -f"
echo "停止:     systemctl stop mihomo; systemctl disable mihomo"
echo "系统代理(未开 TUN 时三选一):"
echo "  1) 重跑脚本 ENABLE_TUN=1 开全局 TUN"
echo "  2) 桌面环境 设置 → 网络 → 代理 → 手动 127.0.0.1:${MIXED_PORT}"
echo "  3) 终端临时: export http_proxy=http://127.0.0.1:${MIXED_PORT} https_proxy=http://127.0.0.1:${MIXED_PORT} all_proxy=socks5://127.0.0.1:${SOCKS_PORT}"
