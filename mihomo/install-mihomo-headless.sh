#!/bin/bash
# ============================================================
# 在 macOS 上安装并配置无界面(纯命令行)mihomo 代理
# 替代 Clash Party 等 GUI 客户端,内存占用 ~40MB,无渲染进程泄漏
#
# 用法:
#   ./install-mihomo-headless.sh [订阅URL]
#   订阅 URL 也可通过环境变量 MIHOMO_SUB_URL 提供,或运行时不传则交互输入
#
# 作用:
#   1. brew 安装 mihomo
#   2. 生成 /opt/homebrew/etc/mihomo/config.yaml
#      (proxy-providers 每日自动拉取订阅,免手动更新)
#   3. 下载 zashboard 面板(http://127.0.0.1:9090/ui/)
#   4. brew services 开机自启
#   5. 设置 macOS 系统代理
#
# 注意:订阅 URL 含 token,属敏感信息,勿写死在本脚本中
# ============================================================
set -e

# ---------- 0. 订阅 URL(参数 > 环境变量 > 交互输入) ----------
SUB_URL="${1:-$MIHOMO_SUB_URL}"
if [ -z "$SUB_URL" ]; then
  read -rp "请输入机场订阅 URL: " SUB_URL
fi
[ -z "$SUB_URL" ] && { echo "错误:未提供订阅 URL"; exit 1; }

# ---------- 1. 安装 mihomo ----------
if ! command -v mihomo >/dev/null 2>&1; then
  echo ">> 安装 mihomo ..."
  brew install mihomo
fi
MIHOMO_BIN="$(command -v mihomo)"

# ---------- 2. 常量 ----------
MIXED_PORT=7890          # HTTP+SOCKS 混合端口
SOCKS_PORT=7891          # SOCKS 独立端口
HTTP_PORT=7892           # HTTP 独立端口
CTRL_PORT=9090           # external-controller(API/面板)
CFG_DIR="$(brew --prefix)/etc/mihomo"
NET_SERVICE="${NET_SERVICE:-}"   # 可覆盖;留空则自动取第一个网络服务

# ---------- 3. 生成随机 API 密钥(见 config.yaml 的 secret) ----------
SECRET="$(head -c 16 /dev/urandom | xxd -p -c 32)"

# ---------- 4. 备份旧配置 ----------
if [ -f "$CFG_DIR/config.yaml" ]; then
  mkdir -p ~/claude-temp
  cp "$CFG_DIR/config.yaml" "$HOME/claude-temp/mihomo-config-backup-$(date +%Y%m%d-%H%M%S).yaml"
  echo ">> 旧配置已备份到 ~/claude-temp/"
fi
mkdir -p "$CFG_DIR" "$CFG_DIR/ui"

# ---------- 5. 写入配置 ----------
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
  enable: false
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
echo ">> 配置已写入 $CFG_DIR/config.yaml (secret 在文件里)"

# ---------- 6. 校验配置 ----------
echo ">> 校验配置 ..."
"$MIHOMO_BIN" -t -d "$CFG_DIR" >/dev/null 2>&1 || {
  echo "配置校验失败:"
  "$MIHOMO_BIN" -t -d "$CFG_DIR"
  exit 1
}

# ---------- 7. 启动服务(开机自启) ----------
brew services restart mihomo >/dev/null
echo ">> mihomo 已启动并注册开机自启"

# 等待端口就绪
for _ in $(seq 1 15); do
  lsof -iTCP:"$MIXED_PORT" -sTCP:LISTEN >/dev/null 2>&1 && break
  sleep 1
done

# ---------- 8. 下载 zashboard 面板(走刚启动的代理) ----------
curl -sL -x "http://127.0.0.1:${MIXED_PORT}" -o /tmp/mihomo-zashboard.zip \
  https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip || true
if [ -s /tmp/mihomo-zashboard.zip ]; then
  unzip -o -q /tmp/mihomo-zashboard.zip -d "$CFG_DIR/ui"
  # zip 内含 dist/ 子目录,提升到 ui/ 根目录
  if [ -d "$CFG_DIR/ui/dist" ]; then
    mv "$CFG_DIR/ui/dist"/* "$CFG_DIR/ui/"
    rmdir "$CFG_DIR/ui/dist"
  fi
  mv -f /tmp/mihomo-zashboard.zip "$HOME/claude-temp/mihomo-zashboard.zip"
  echo ">> zashboard 面板已装: http://127.0.0.1:${CTRL_PORT}/ui/"
else
  echo "!! 面板下载失败(可稍后手动补装),不影响代理使用"
fi

# ---------- 9. 设置系统代理 ----------
if [ -z "$NET_SERVICE" ]; then
  NET_SERVICE="$(networksetup -listallnetworkservices 2>/dev/null | sed -n '2p')"
fi
if [ -n "$NET_SERVICE" ] && [ "$NET_SERVICE" != "*" ]; then
  networksetup -setwebproxy "$NET_SERVICE" 127.0.0.1 "$MIXED_PORT"
  networksetup -setsecurewebproxy "$NET_SERVICE" 127.0.0.1 "$MIXED_PORT"
  networksetup -setsocksfirewallproxy "$NET_SERVICE" 127.0.0.1 "$MIXED_PORT"
  networksetup -setproxybypassdomains "$NET_SERVICE" \
    127.0.0.1 192.168.0.0/16 10.0.0.0/8 172.16.0.0/12 localhost "*.local" "*.crashlytics.com" \
    "<local>" "*.caijj.net" "*.bing.com" "*.baidu.com" "*.bilibili.com" "*.163.com" "*.sina.com" \
    "*.weibo.com" "*.wx.com" "*.wexin.com" "*.wechat.com" "*.doubao.com" "*.tencent.com" \
    "*.aliyun.com" "*.volcengine.com" "*.qianwen.com" "*.shuheo.net"
  echo ">> 系统代理已设置($NET_SERVICE -> 127.0.0.1:${MIXED_PORT})"
else
  echo "!! 未识别网络服务,请手动设置系统代理:"
  echo "   networksetup -setwebproxy <服务名> 127.0.0.1 ${MIXED_PORT}"
fi

# ---------- 10. 验证 ----------
echo ">> 验证代理连通 ..."
curl -s -o /dev/null -w "   HTTP %{http_code} in %{time_total}s\n" \
  -x "http://127.0.0.1:${MIXED_PORT}" https://www.gstatic.com/generate_204 --max-time 20

echo
echo "=== 完成 ==="
echo "切节点:   浏览器打开 http://127.0.0.1:${CTRL_PORT}/ui/ 输入密钥"
echo "手动更新: curl -X PUT -H 'Authorization: Bearer <secret>' http://127.0.0.1:${CTRL_PORT}/providers/proxies/三毛机场订阅"
echo "查日志:   tail -f $(brew --prefix)/var/log/mihomo.log"
echo "停止:     brew services stop mihomo"
