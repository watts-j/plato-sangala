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

# Allow Nickel to fully initialize before handing off to Plato
sleep 12
log "launching plato.sh"

# Launch Plato
exec /mnt/onboard/.adds/plato/plato.sh
