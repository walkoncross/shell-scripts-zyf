<#
  Windows 版:安装并配置无界面(纯命令行)mihomo 代理
  与 macOS/Linux 版配置互通,差异仅在:
    - 下载 GitHub 预编译二进制 mihomo.exe(含 ghfast 镜像回退)
    - Windows 服务(sc.exe)代替 systemd/brew services
    - 系统代理写注册表(HKCU),可选 TUN

  用法(建议在 PowerShell 中执行):
    .\install-mihomo-headless-windows.ps1 -SubUrl "<订阅URL>"
    或
    $env:MIHOMO_SUB_URL = "<订阅URL>"; .\install-mihomo-headless-windows.ps1
    或运行后按提示交互输入订阅 URL

  可选参数:
    -SubUrl     机场订阅 URL(含 token,勿写死)
    -Version    mihomo 版本号,默认 1.19.30
    -InstallDir 安装目录,默认 C:\mihomo
    -EnableTun  启用 TUN 全局代理(需管理员)
    -AsService  安装为 Windows 服务并启动(需管理员,推荐)
    -SetProxy   设置系统代理 127.0.0.1:7890(HKCU,无需管理员)
#>
param(
    [string]$SubUrl = $env:MIHOMO_SUB_URL,
    [string]$Version = "1.19.30",
    [string]$InstallDir = "C:\mihomo",
    [switch]$EnableTun,
    [switch]$AsService,
    [switch]$SetProxy
)
$ErrorActionPreference = "Stop"

# ---------- 0. 订阅 URL ----------
if ([string]::IsNullOrWhiteSpace($SubUrl)) {
    $SubUrl = Read-Host "请输入机场订阅 URL"
}
if ([string]::IsNullOrWhiteSpace($SubUrl)) {
    Write-Error "未提供订阅 URL"
    exit 1
}

# ---------- 1. 管理员检测 ----------
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (($AsService -or $EnableTun) -and -not $isAdmin) {
    Write-Error "安装服务(-AsService)/启用 TUN(-EnableTun)需要管理员权限,请用管理员身份运行 PowerShell"
    exit 1
}

# ---------- 2. 架构识别 ----------
$arch = $env:PROCESSOR_ARCHITECTURE
if ($arch -eq "x86" -and $env:PROCESSOR_ARCHITEW6432) { $arch = $env:PROCESSOR_ARCHITEW6432 }
switch ($arch) {
    "AMD64" { $binArch = "amd64" }
    "ARM64" { $binArch = "arm64" }
    default { Write-Error "不支持的架构: $arch (可用 amd64/arm64, 老 CPU 换 -compatible 包)"; exit 1 }
}

# ---------- 3. 下载 mihomo(直连失败回退 ghfast 镜像) ----------
$exePath = Join-Path $InstallDir "mihomo.exe"
if (-not (Test-Path $exePath)) {
    $zipUrl = "https://github.com/MetaCubeX/mihomo/releases/download/v$Version/mihomo-windows-$binArch-v$Version.zip"
    $zipPath = Join-Path $env:TEMP "mihomo-$Version.zip"
    Write-Host ">> 下载 mihomo $Version ($binArch) ..."
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -fsSL -o $zipPath $zipUrl
        if ($LASTEXITCODE -ne 0) {
            & curl.exe -fsSL -o $zipPath "https://ghfast.top/$zipUrl"
        }
    }
    if (-not (Test-Path $zipPath) -or (Get-Item $zipPath).Length -eq 0) {
        try {
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 60
        } catch {
            Invoke-WebRequest -Uri "https://ghfast.top/$zipUrl" -OutFile $zipPath -UseBasicParsing -TimeoutSec 60
        }
    }
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
    # 若 zip 内还有一层目录,递归找到 mihomo.exe
    if (-not (Test-Path $exePath)) {
        $found = Get-ChildItem -Path $InstallDir -Recurse -Filter "mihomo.exe" | Select-Object -First 1
        if ($found) { Copy-Item -Path $found.FullName -Destination $exePath -Force }
    }
    Write-Host ">> mihomo.exe 已装到 $exePath"
}
if (-not (Test-Path $exePath)) {
    Write-Error "未找到 mihomo.exe,请检查下载"
    exit 1
}

# ---------- 4. 生成随机 API 密钥 ----------
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 16
$rng.GetBytes($bytes)
$secret = -join ($bytes | ForEach-Object { $_.ToString("x2") })
$rng.Dispose()

# ---------- 5. 写入配置 ----------
$tunEnable = if ($EnableTun) { "true" } else { "false" }
$config = @'
mixed-port: 7890
allow-lan: false
bind-address: "*"
external-controller: 127.0.0.1:9090
secret: __SECRET__
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
    url: __SUB_URL__
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
socks-port: 7891
port: 7892
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
  enable: __TUN_ENABLE__
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
'@
$config = $config.Replace("__SUB_URL__", $SubUrl).Replace("__SECRET__", $secret).Replace("__TUN_ENABLE__", $tunEnable)

# 备份旧配置
$configPath = Join-Path $InstallDir "config.yaml"
if (Test-Path $configPath) {
    $backupDir = Join-Path $env:USERPROFILE "claude-temp"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    Copy-Item $configPath (Join-Path $backupDir ("mihomo-config-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".yaml"))
    Write-Host ">> 旧配置已备份到 $backupDir"
}

# 写 UTF-8(无 BOM)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($configPath, $config, $utf8NoBom)
Write-Host ">> 配置已写入 $configPath (secret 在文件里, TUN=$tunEnable)"

# ---------- 6. 下载 zashboard 面板(失败不影响代理) ----------
$uiDir = Join-Path $InstallDir "ui"
$uiZip = Join-Path $env:TEMP "zashboard.zip"
$uiUrl = "https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip"
try {
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        & curl.exe -fsSL -o $uiZip $uiUrl
        if ($LASTEXITCODE -ne 0) { & curl.exe -fsSL -o $uiZip "https://ghfast.top/$uiUrl" }
    }
    if (-not (Test-Path $uiZip) -or (Get-Item $uiZip).Length -eq 0) {
        Invoke-WebRequest -Uri $uiUrl -OutFile $uiZip -UseBasicParsing -TimeoutSec 60
    }
    New-Item -ItemType Directory -Force -Path $uiDir | Out-Null
    Expand-Archive -Path $uiZip -DestinationPath $uiDir -Force
    $dist = Join-Path $uiDir "dist"
    if (Test-Path $dist) {
        Copy-Item -Path (Join-Path $dist "*") -Destination $uiDir -Recurse -Force
        Remove-Item -Path $dist -Recurse -Force
    }
    Write-Host ">> zashboard 面板已装: http://127.0.0.1:9090/ui/"
} catch {
    Write-Host "!! 面板下载失败(可稍后手动补装),不影响代理使用"
}

# ---------- 7. 安装为 Windows 服务 ----------
if ($AsService) {
    $binArg = '"' + $exePath + '" -d "' + $InstallDir + '"'
    & sc.exe delete mihomo | Out-Null
    Start-Process -FilePath "sc.exe" -ArgumentList @("create", "mihomo", "binPath= $binArg", "start= auto") -Wait -NoNewWindow
    Start-Process -FilePath "sc.exe" -ArgumentList @("start", "mihomo") -Wait -NoNewWindow
    Write-Host ">> 服务 mihomo 已创建并启动(开机自启)"
}

# ---------- 8. 设置系统代理 ----------
if ($SetProxy) {
    $reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    Set-ItemProperty -Path $reg -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $reg -Name ProxyServer -Value "127.0.0.1:7890"
    Set-ItemProperty -Path $reg -Name ProxyOverride -Value "localhost;<local>"
    Write-Host ">> 已设置系统代理 127.0.0.1:7890(重启应用后生效)"
}

# ---------- 9. 输出用法 ----------
Write-Host ""
Write-Host "=== 完成 ==="
if (-not $AsService) {
    Write-Host "手动启动:   $exePath -d `"$InstallDir`""
    Write-Host "         (首次运行会弹防火墙授权,请勾选允许)"
    Write-Host "开机自启:   重跑本脚本加 -AsService,或用 nssm"
}
Write-Host "切节点:    浏览器打开 http://127.0.0.1:9090/ui/ 输入密钥"
Write-Host "手动更新:  curl -X PUT -H 'Authorization: Bearer <secret>' http://127.0.0.1:9090/providers/proxies/三毛机场订阅"
Write-Host "验证:      curl -x http://127.0.0.1:7890 https://www.gstatic.com/generate_204"
Write-Host "注意:      geoip.dat/geosite.dat 若首次启动下载慢,可从其他设备复制到 $InstallDir"
