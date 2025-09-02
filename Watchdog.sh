cat >/root/tp-watchdog.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
bad=0
while read -r line; do
  [[ "$line" =~ ^tm_p([0-9]+)[[:space:]]+ ]] || continue
  c="${BASH_REMATCH[0]%% *}"
  https=$(awk '{print $NF}' <<<"$line")
  http=$(awk '{print $(NF-1)}' <<<"$line")
  if [[ "$http" != "OK" ]] || [[ "$https" == "FAIL" ]]; then
    echo "[watchdog] $c unhealthy (HTTP=$http HTTPS=$https) -> restarting"
    docker restart "${c}_tp" "$c" || true
    bad=$((bad+1))
  fi
done < <(/root/tp-check.sh | tail -n +2)
exit $bad
EOF
chmod +x /root/tp-watchdog.sh

# Jalankan via cron tiap 5 menit
( crontab -l 2>/dev/null; echo '*/5 * * * * (/root/tp-watchdog.sh || true) >> /var/log/tp-watchdog.log 2>&1' ) | crontab -
