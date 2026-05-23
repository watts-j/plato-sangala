#!/bin/sh

LOG="/mnt/onboard/.adds/plato/autostart.log"
log() { echo "[$(date)] $*" >> "$LOG" 2>/dev/null; }

log "plato-autostart.sh: starting"

# Wait for Nickel to be running
i=0
until pidof nickel > /dev/null 2>&1; do
    sleep 1
    i=$((i + 1))
done
log "nickel up after ${i}s wait"

# Wait for KoboReader.sqlite to exist (covers factory-reset DB build).
# On subsequent boots the file is already there, so this is ~0s.
DB="/mnt/onboard/.kobo/KoboReader.sqlite"
j=0
while [ ! -e "${DB}" ] && [ "$j" -lt 60 ]; do
    sleep 1
    j=$((j + 1))
done
log "KoboReader.sqlite present after ${j}s additional wait"

# Brief grace so any final init writes can flush
sleep 5

pkill -f on-animator > /dev/null 2>&1
log "killed on-animator; launching plato.sh"

exec /mnt/onboard/.adds/plato/plato.sh
