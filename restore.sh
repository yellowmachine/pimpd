#!/bin/bash
set -e

# Obtiene el directorio donde está este script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Cambia a ese directorio
cd "$SCRIPT_DIR"

echo "Restaurando la imagen de backup 'app:restore' como 'app:latest'..."

docker tag app:restore app:latest
docker compose up -d --force-recreate --remove-orphans app

echo "Restauración completa. El servicio 'app' está corriendo con la imagen 'app:latest'."
