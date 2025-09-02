cat >tp-entry.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Expect: $UPSTREAM, contoh:
#   http://user:pass@23.95.150.145:6114
#   http://user:pass@198.23.239.134:6540
: "${UPSTREAM:?UPSTREAM env is required}"

# 1) generate redsocks config
cat >/etc/redsocks.conf <<CONF
base {
  log_debug = off;
  log_info = on;
  daemon = on;
  redirector = iptables;
}
redsocks {
  local_ip = 0.0.0.0;
  local_port = 12345;
  ip = $(echo "$UPSTREAM" | sed -E 's#^.*@([^:/]+).*$#\1#');
  port = $(echo "$UPSTREAM" | sed -E 's#^.*:([0-9]+)/?.*$#\1#');
  type = http-connect;
  login = $(echo "$UPSTREAM" | sed -E 's#^.+://([^:]+):.*$#\1#');
  password = $(echo "$UPSTREAM" | sed -E 's#^.+://[^:]+:([^@]+)@.*$#\1#');
}
CONF

# 2) routing policy & iptables TPROXY (80 & 443)
# hapus rule lama jika ada (idempoten)
iptables -t mangle -F || true
iptables -t mangle -X DIVERT || true
ip rule del fwmark 1 lookup 100 2>/dev/null || true
ip route flush table 100 2>/dev/null || true

# buat table/mark untuk tproxy
ip rule add fwmark 1 lookup 100
ip route add local 0.0.0.0/0 dev lo table 100

iptables -t mangle -N DIVERT
iptables -t mangle -A PREROUTING -p tcp -m socket -j DIVERT
iptables -t mangle -A DIVERT -j MARK --set-mark 1
iptables -t mangle -A DIVERT -j ACCEPT

# tangkap HTTP & HTTPS
for dport in 80 443; do
  iptables -t mangle -A PREROUTING -p tcp --dport $dport -j TPROXY \
    --on-port 12345 --tproxy-mark 0x1/0x1
done

# 3) start redsocks
redsocks -c /etc/redsocks.conf

echo "  [tp] transparent proxy active via $(echo "$UPSTREAM" | sed 's#^.*@##')"
# jaga container tetap hidup
tail -f /dev/null
EOF
chmod +x tp-entry.sh
