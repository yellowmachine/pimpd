#!/bin/sh

# --- Configuración ---
REPO_URL="https://github.com/yellowmachine/qwikmpd" # ¡CAMBIA ESTO por la URL de tu repo!
APP_SERVICE_NAME="app" # ¡CAMBIA ESTO por el nombre de tu servicio de app en docker-compose.yml!
GIT_BRANCH="main"
WORK_DIR="/tmp/repo_check"
LOG_FILE="/var/log/app_version_check.log" # Ruta para los logs dentro del contenedor
APP_UPDATE_ENDPOINT="http://app:3000/api/version"

# --- Funciones ---

# Función para registrar mensajes
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --- Lógica principal ---

log_message "Iniciando chequeo de nueva versión para $APP_SERVICE_NAME..."

# Crear o limpiar directorio de trabajo
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || { log_message "Error: No se pudo cambiar al directorio de trabajo $WORK_DIR"; exit 1; }

# Clonar o hacer pull del repositorio para obtener el HEAD más reciente sin descargar todo el historial
# Usamos --depth 1 para solo obtener el último commit
if [ -d ".git" ]; then
    log_message "Repository already cloned, fetching latest commit..."
    git fetch origin "$GIT_BRANCH" || { log_message "Error: No se pudo hacer fetch del repositorio."; exit 1; }
else
    log_message "Cloning repository $REPO_URL..."
    git clone --depth 1 --branch "$GIT_BRANCH" "$REPO_URL" . || { log_message "Error: No se pudo clonar el repositorio."; exit 1; }
fi

# Obtener el SHA del último commit de la rama remota
LATEST_REMOTE_SHA=$(git rev-parse "origin/$GIT_BRANCH")
if [ -z "$LATEST_REMOTE_SHA" ]; then
    log_message "Error: No se pudo obtener el SHA del commit remoto."
    exit 1
fi

# Obtener el SHA del commit actual que está desplegado (asumimos que está en un archivo)
# Esta es una estrategia simple. Podrías leer el commit actual de tu imagen Docker o de un archivo.
# Para este ejemplo, asumimos que 'current_deployed_sha.txt' guarda el último SHA desplegado.
DEPLOYED_SHA_FILE="/data/current_deployed_sha.txt" # Asegúrate que este path esté mapeado a un volumen persistente

# Leer el SHA del último despliegue (si existe)
if [ -f "$DEPLOYED_SHA_FILE" ]; then
    CURRENT_DEPLOYED_SHA=$(cat "$DEPLOYED_SHA_FILE")
    log_message "SHA actual desplegado: $CURRENT_DEPLOYED_SHA"
else
    CURRENT_DEPLOYED_SHA=""
    log_message "No se encontró un SHA desplegado previamente. Consideraremos esto como el primer despliegue o un despliegue inicial."
fi

# Comparar SHAs
if [ "$LATEST_REMOTE_SHA" != "$CURRENT_DEPLOYED_SHA" ]; then
    log_message "¡Nueva versión detectada!"
    log_message "SHA remoto: $LATEST_REMOTE_SHA"
    log_message "SHA actual: $CURRENT_DEPLOYED_SHA"

    # --- Acciones de Actualización ---
    log_message "Iniciando actualización de la aplicación $APP_SERVICE_NAME via HTTP POST a $APP_UPDATE_ENDPOINT..."
    /home/miguel/platform/pimpd/update.sh

else
    log_message "No se realiza accion."
fi
