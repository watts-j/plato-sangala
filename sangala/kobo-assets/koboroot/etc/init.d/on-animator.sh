#!/bin/sh

# Launch Plato autostart in background
PLATO_AUTOSTART="/usr/local/bin/plato-autostart.sh"
if [ -x "${PLATO_AUTOSTART}" ] ; then
	"${PLATO_AUTOSTART}" &
fi

# Default Kobo boot animation
PRODUCT="$(/bin/sh /bin/kobo_config.sh)"
[ "${PRODUCT}" != "trilogy" ] && PREFIX="${PRODUCT}-"
COLOR="OFF"
if [ -e "/dev/mmcblk0p6" ] ; then
	COLOR="$(ntx_hwconfig -S 1 -p /dev/mmcblk0p6 EPD_Flags CFA)"
fi

PARTIAL_UPDATE=1
if [ "${COLOR}" = "ON" ] ; then
	PARTIAL_UPDATE=0
fi

i=0
while true ; do
	i=$(( (i + 1) % 11 ))
	image="/etc/images/${PREFIX}on-${i}.raw.gz"
	if [ -s "${image}" ] ; then
		zcat "${image}" | /usr/local/Kobo/pickel showpic ${PARTIAL_UPDATE}
		PARTIAL_UPDATE=1
		usleep 250000
	fi
done
