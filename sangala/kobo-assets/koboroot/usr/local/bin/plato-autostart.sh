#!/bin/sh

# Wait for Nickel to be running
until pidof nickel > /dev/null 2>&1; do
    sleep 1
done

# Wait for Nickel's end-of-animation marker (set after the boot animation
# phase completes; on a factory-reset device this also implies FTE prep is
# done). Cap the wait at 60s so a missing marker doesn't hang forever.
ANIM_FLAG="/tmp/end_of_animation"
i=0
while [ ! -e "${ANIM_FLAG}" ] && [ "$i" -lt 60 ]; do
    sleep 1
    i=$((i + 1))
done

# Brief grace period so Nickel finishes settling before plato.sh kills it
sleep 3

# Hand off to Plato
exec /mnt/onboard/.adds/plato/plato.sh
