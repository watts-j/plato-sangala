#!/bin/sh

LOG="/mnt/onboard/.adds/plato/autostart.log"
log() { echo "[$(date)] $*" >> "$LOG" 2>/dev/null; }

log "plato-autostart.sh: starting"

DB="/mnt/onboard/.kobo/KoboReader.sqlite"

# If the DB is already present at script start, this is a normal subsequent
# boot (post-install, post-reboot, etc.). Nickel has nothing to set up and
# can be killed as soon as it appears, with no grace, to keep it from ever
# becoming visible on screen. If the DB is missing, this is a factory-reset
# first boot and we have to give Nickel time to build the DB before we kill
# it -- otherwise the device hangs on the loading dots.
if [ -e "${DB}" ]; then
    SUBSEQUENT_BOOT=1
    log "DB present at start -- subsequent boot, no grace will be applied"
else
    SUBSEQUENT_BOOT=0
    log "DB missing at start -- factory-reset path, will wait for DB and grace"
fi

# Wait for Nickel to be running.
i=0
until pidof nickel > /dev/null 2>&1; do
    sleep 1
    i=$((i + 1))
done
log "nickel up after ${i}s wait"

if [ "${SUBSEQUENT_BOOT}" -eq 0 ]; then
    # Factory-reset case: wait for Nickel to finish building the DB.
    j=0
    while [ ! -e "${DB}" ] && [ "$j" -lt 60 ]; do
        sleep 1
        j=$((j + 1))
    done
    log "KoboReader.sqlite present after ${j}s additional wait"
    # Brief grace so Nickel's DB-init writes flush before we kill it.
    sleep 5
    log "post-DB grace done"
fi

pkill -f on-animator > /dev/null 2>&1
log "killed on-animator; launching plato.sh"

exec /mnt/onboard/.adds/plato/plato.sh
