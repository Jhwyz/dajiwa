#!/bin/bash
# V:jhwlkjcloud
# 两行显示 + UUID 自动生成版

AUTHOR="====================================  V:jhwlkjcloud  ===================================="
echo "$AUTHOR"

PASSWORD="Yue990304"
echo -n "请输入密码以继续: "
read -s input_password
echo
if [[ "$input_password" != "$PASSWORD" ]]; then
    echo "密码错误，脚本退出！"
    exit 1
fi
stty sane

read -e -p "请输入你的域名: " DOMAIN
EMAIL="your-email@example.com"
UUID=$(cat /proc/sys/kernel/random/uuid)

print_step() {
    echo -ne "\r\033[K$1"
}

print_step "✅ 创建 Caddy 文件夹并下载..."
sudo mkdir -p /etc/caddy &>/dev/null
cd /etc/caddy || exit
sudo wget -q https://github.com/caddyserver/caddy/releases/download/v2.10.0/caddy_2.10.0_linux_amd64.tar.gz
sudo tar -xzf caddy_2.10.0_linux_amd64.tar.gz
sudo rm -f caddy_2.10.0_linux_amd64.tar.gz

print_step "✅ 创建 Caddyfile..."
cat <<EOC | sudo tee /etc/caddy/Caddyfile &>/dev/null
$DOMAIN {
    encode gzip
    tls $EMAIL
    reverse_proxy /$UUID* 127.0.0.1:54864
}
EOC

print_step "✅ 安装 V2Ray..."
bash <(curl -L -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) &>/dev/null

print_step "✅ 配置 V2Ray..."
cat <<EOC | sudo tee /usr/local/etc/v2ray/config.json &>/dev/null
{
  "inbounds":[{"port":54864,"listen":"127.0.0.1","protocol":"vmess","settings":{"clients":[{"id":"$UUID","alterId":0}]},"streamSettings":{"network":"ws","security":"none","wsSettings":{"path":"/$UUID"}}}],
  "outbounds":[{"protocol":"freedom","settings":{}}],
  "dns":{"servers":["8.8.8.8","1.1.1.1"]}
}
EOC

print_step "✅ 修改 systemd 文件..."
sudo sed -i "7s/.*/User=v2ray/" /etc/systemd/system/v2ray.service &>/dev/null
sudo sed -i "7s/.*/User=v2ray/" /etc/systemd/system/v2ray@.service &>/dev/null

print_step "✅ 创建 caddy.service..."
cat <<EOC | sudo tee /etc/systemd/system/caddy.service &>/dev/null
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target nss-lookup.target
[Service]
User=root
ExecStart=/etc/caddy/caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
Restart=on-failure
RestartPreventExitStatus=23
[Install]
WantedBy=multi-user.target
EOC

print_step "✅ 启动服务..."
sudo systemctl daemon-reload &>/dev/null
sudo systemctl enable v2ray &>/dev/null
sudo systemctl start v2ray &>/dev/null
sudo systemctl enable caddy &>/dev/null
sudo systemctl start caddy &>/dev/null

echo -e "\r\033[K🎉 脚本执行完毕！"
echo "V2Ray UUID: $UUID"
echo "WebSocket 路径: /$UUID"
