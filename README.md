# Traffmonetizer_Docker
Aplikasi traffmonetizer yang bisa running 10 container dengan 1 container 1 proxy

apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release iptables iproute2

# Docker CE (resmi) – aman & stabil
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# === 0b. Sysctl untuk TPROXY (wajib) ===
cat >/etc/sysctl.d/99-tproxy.conf <<'EOF'
net.ipv4.ip_forward=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.lo.rp_filter=0
# route local table diperlukan untuk TPROXY
net.ipv4.conf.all.route_localnet=1
EOF
sysctl --system

# (opsional) Pastikan pakai iptables-legacy jika kernel/host perlu
update-alternatives --set iptables /usr/sbin/iptables-legacy 2>/dev/null || true
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy 2>/dev/null || true

# === 0c. Workspace ===
mkdir -p /home/ubuntu/traffmonetizer
cd /home/ubuntu/traffmonetizer
