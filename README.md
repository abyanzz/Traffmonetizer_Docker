# Traffmonetizer_Docker
Aplikasi traffmonetizer yang bisa running 10 container dengan 1 container 1 proxy


docker compose -f docker-compose.transparent.yml config >/dev/null && echo "YAML OK"
docker compose -f docker-compose.transparent.yml up -d --force-recreate

