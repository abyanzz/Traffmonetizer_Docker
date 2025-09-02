cat >/root/tp-check.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
pads() { printf "%-10s %-22s %-16s %-16s %-16s %-12s %-6s\n" "$@"; }

pads "CONTAINER" "UPSTREAM" "icanhazip" "ipify(http)" "ifconfig.me" "HTTP" "HTTPS"
for i in $(seq 1 10); do
  tm="tm_p$i"; tp="tm_p${i}_tp"
  up=$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$tp" 2>/dev/null \
      | grep -E '^UPSTREAM=' | head -n1 | cut -d= -f2-)
  up=${up:-"-"}

  ip1=$(docker exec "$tm" sh -lc 'wget -qO- http://ipv4.icanhazip.com || true')
  ip2=$(docker exec "$tm" sh -lc 'wget -qO- http://api.ipify.org || true')
  ip3=$(docker exec "$tm" sh -lc 'wget -qO- http://ifconfig.me/ip || true')

  http=$(docker exec "$tm" sh -lc 'wget --spider -q http://example.com && echo OK || echo FAIL')

  https=$(docker exec "$tm" sh -lc '
    if command -v curl >/dev/null 2>&1; then
      http_proxy= HTTPS_PROXY= HTTPS_PROXY= \
      curl -s --max-time 6 https://api.ipify.org >/dev/null && echo OK || echo FAIL
    else
      echo "-"
    fi' 2>/dev/null)

  printf "%-10s %-22s %-16s %-16s %-16s %-12s %-6s\n" \
    "$tm" "${up:0:22}" "${ip1:0:15}" "${ip2:0:15}" "${ip3:0:15}" "$http" "$https"
done
EOF

chmod +x /root/tp-check.sh
/root/tp-check.sh
