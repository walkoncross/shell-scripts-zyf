#!/usr/bin/env bash
set -u

uid=$(id -u)

echo "Enabling system LaunchDaemons..."
for label in \
  com.cg.data.endpoint.pro \
  CirrusGate.DLP3 \
  com.citrix.ctxusbd \
  com.lvmagent.core \
  com.lvmagent.filemonitor \
  com.qihoo.360safe.daemon \
  com.sangfor.aTrustTunnel \
  com.sangfor.aTrustUninstallMonitor \
  com.sangfor.limit.maxfiles \
  com.docker.socket \
  com.docker.vmnetd \
  com.youqu.todesk.service \
  com.youqu.todesk.UninstallerHelper \
  com.youqu.todesk.UninstallerWatcher \
  party.mihomo.helper
do
  sudo launchctl enable "system/$label" 2>/dev/null || true
  sudo launchctl bootstrap system "/Library/LaunchDaemons/$label.plist" 2>/dev/null || true
done

echo "Enabling user LaunchAgents..."
for label in \
  CGEData.user.agent \
  com.citrix.AuthManager_Mac \
  com.citrix.ReceiverHelper \
  com.citrix.ServiceRecords \
  com.lvmagent.gui \
  com.lvmagent.screen \
  com.sangfor.aTrustCore \
  com.sangfor.aTrustDaemon \
  com.sangfor.aTrustTray \
  com.sogou.SogouServices \
  com.sogou.SogouTaskManager \
  com.youqu.todesk.desktop \
  com.youqu.todesk.client.startup
do
  launchctl enable "gui/$uid/$label" 2>/dev/null || true
  launchctl bootstrap "gui/$uid" "/Library/LaunchAgents/$label.plist" 2>/dev/null || true
done

echo "Checking loaded third-party items..."
launchctl list | egrep 'cg|CirrusGate|citrix|lvmagent|qihoo|sangfor|aTrust|sogou|todesk|docker|mihomo' || true

echo "Checking disabled system items..."
launchctl print-disabled system | egrep 'cg|CirrusGate|citrix|lvmagent|qihoo|sangfor|aTrust|todesk|docker|mihomo' || true

echo "Checking disabled user items..."
launchctl print-disabled "gui/$uid" | egrep 'cg|citrix|lvmagent|sangfor|aTrust|sogou|todesk' || true

echo "Done. A reboot is recommended to confirm startup behavior."
