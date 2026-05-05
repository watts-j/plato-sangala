#!/bin/sh

# Wait for Nickel to be running
until pidof nickel > /dev/null 2>&1; do
    sleep 1
done

# Allow Nickel to fully initialize before handing off to Plato
sleep 12

# Launch Plato
exec /mnt/onboard/.adds/plato/plato.sh
