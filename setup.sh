#!/bin/bash

# Crea las carpetas si no existen
mkdir -p ./music
mkdir -p ./playlists

# Asigna propietario y grupo (ajusta según tu sistema)
sudo chown -R nobody:nogroup ./music ./playlists

# Da permisos de lectura y escritura para propietario y grupo, lectura para otros
chmod -R 775 ./music ./playlists

echo "Carpetas 'music' y 'playlists' preparadas con permisos correctos."
