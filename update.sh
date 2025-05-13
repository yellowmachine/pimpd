#!/bin/bash
set -e

# Ruta absoluta del lockfile (ajusta si lo prefieres en otro sitio)
LOCKFILE="/tmp/update_app.lock"

# Intenta adquirir el lock de forma no bloqueante
exec 9>"$LOCKFILE"
if ! flock -n 9; then
  echo "Ya hay una actualización en curso. Abortando." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGFILE="$SCRIPT_DIR/update_app.log"

{
  echo "=============================="
  echo "Actualización iniciada: $(date)"
  echo "Reconstruyendo la imagen de 'app' sin caché..."
  cd "$SCRIPT_DIR"

  if docker image inspect app:latest >/dev/null 2>&1; then
    docker tag app:latest app:restore
  fi

  docker compose build --no-cache app

  echo "Reiniciando el servicio 'app'..."
  nohup bash -c 'docker compose down app && sleep 2 && docker compose up -d app' >> "$LOGFILE" 2>&1 &

  #docker compose down app
  #nohup docker compose up app -d >> "$LOGFILE" 2>&1 &

  echo "Actualización completada. Por favor, refresca la pantalla en unos segundos para ver los cambios."
  echo
} 2>&1 | tee -a "$LOGFILE"

