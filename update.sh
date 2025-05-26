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
SHA_FILE="$SCRIPT_DIR/data/current_deployed_sha.txt"

# Comprueba si el log existe y lo renombra/elimina antes de empezar a escribir en él
if [ -f "$LOGFILE" ]; then
    # Opción A: Renombrar para guardar una copia anterior (ej. update_app.log.old)
    mv "$LOGFILE" "${LOGFILE}.old"
    echo "Log anterior renombrado a ${LOGFILE}.old"

    # Opción B: Eliminar el log anterior (si no necesitas historial)
    # rm "$LOGFILE"
    # echo "Log anterior eliminado."
fi

{
  echo "=============================="
  echo "Actualización iniciada: $(date)"
  echo "Reconstruyendo la imagen de 'app' sin caché..."
  cd "$SCRIPT_DIR"

  if docker image inspect app:latest >/dev/null 2>&1; then
    docker tag app:latest app:restore
  fi

  docker compose build --no-cache app
  if [ $? -ne 0 ]; then
    echo "Error: Falló la construcción de la imagen 'app'." >&2
    exit 1
  fi

  echo "Reiniciando el servicio 'app'..."
  nohup bash -c 'docker compose down app && sleep 2 && docker compose up -d app' >> "$LOGFILE" 2>&1 &

  #docker compose down app
  #nohup docker compose up app -d >> "$LOGFILE" 2>&1 &

  echo "Actualización completada. Por favor, refresca la pantalla en unos segundos para ver los cambios."
  echo

  REPO_URL="https://github.com/yellowmachine/qwikmpd" 
  BRANCH_NAME="main"

  # Ejecuta git ls-remote y filtra la salida para obtener solo el SHA de la rama deseada
  LAST_COMMIT_SHA=$(git ls-remote "$REPO_URL" "$BRANCH_NAME" | grep "refs/heads/$BRANCH_NAME" | cut -f 1)

  if [ -z "$LAST_COMMIT_SHA" ]; then
    echo "Error: No se pudo obtener el SHA para la rama $BRANCH_NAME en $REPO_URL" >&2
    exit 1
  else
    echo "$LAST_COMMIT_SHA" > "$SHA_FILE"
    echo "SHA del commit '$LAST_COMMIT_SHA' guardado en '$SHA_FILE'."
    exit 0
  fi

} 2>&1 | tee -a "$LOGFILE"

