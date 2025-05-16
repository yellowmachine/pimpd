# pimpd

Deploy a multiroom audio system with `mpd` and `snapserver` integration on a Raspberry Pi.

This setup allows you to synchronize audio playback across multiple rooms using open source software and affordable hardware.

> **Note:** If you intend to deploy on an amd64 (PC) architecture, you must change the `dnsmasq` image in the Docker Compose file to an appropriate one for your system.

---

## Features

- Multiroom audio with [MPD (Music Player Daemon)](https://www.musicpd.org/) and [Snapcast](https://github.com/badaix/snapcast)
- Docker Compose deployment for easy setup
- Designed for Raspberry Pi (ARM architecture)
- Includes `dnsmasq` for local DNS/DHCP

---

## Requirements

- Raspberry Pi (recommended: Pi 3 or newer)
- Raspberry Pi OS Lite (or compatible Debian-based distro)
- Docker and Docker Compose installed

---

## Quick Start

1. **Clone this repository:**

2. **Review and edit environment variables in `.env` as needed.**
 
This is a sample:

```
SNAPCLIENT_OPTS=-h snapserver --hostID namethisclient --latency=100
MPD_SERVER = mpd
SSH_HOST=192.168.1.56
SSH_USER=miguel
SCRIPT_UPDATE_APP_PATH=/home/miguel/platform/pimpd/update.sh
AUTH_TOKEN=secret
RESTORE_SCRIPT=/home/miguel/platform/pimpd/restore.sh
SSH_PATH=/home/miguel/.ssh
API_KEY_LASTFM=yourapikey
```

3. **Start the stack:**

4. **Access the services:**

on port 3000 is running the webapp. You cand edit Caddifile. This is an example:

```
music.casa {
  tls /certs/music.casa.pem /certs/music.casa-key.pem
  reverse_proxy raspberry.casa:3000
}

http://music2.casa {
  reverse_proxy raspberry.casa:3000
}

http://restore.casa {
  reverse_proxy raspberry.casa:3001
}
```
