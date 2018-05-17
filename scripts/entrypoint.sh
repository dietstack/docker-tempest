#!/bin/bash
set -e

if [[ -z ${IMAGE_REF} ]]; then
    echo "WARNING: IMAGE_REF is not set!"
fi

if [[ -z ${PUBLIC_NETWORK_ID} ]]; then
    echo "WARNING: PUBLIC_NETWORK_ID is not set!"
fi

if [[ -f /app/settings.sh ]]; then
  . /app/settings.sh
fi

if [[ -n ${EXTERNAL_IP} ]]; then
    CONTROLLER_IP=$(cut -d'/' -f 1 <<< "${EXTERNAL_IP}")
fi

CONTROLLER_IP=${CONTROLLER_IP:-192.168.99.1}

LOG_MESSAGE="Docker start script:"
OVERRIDE=0
CONF_DIR="/etc/tempest"
OVERRIDE_DIR="/tempest-override"
CONF_FILES=(`cd $CONF_DIR; find . -maxdepth 3 -type f`)

# check if external configs are provided
echo "$LOG_MESSAGE Checking if external config is provided.."
if [[ -f "$OVERRIDE_DIR/${CONF_FILES[0]}" ]]; then
        echo "$LOG_MESSAGE  ==> external config found!. Using it."
        OVERRIDE=1
        for CONF in ${CONF_FILES[*]}; do
                rm -f "$CONF_DIR/$CONF"
                ln -s "$OVERRIDE_DIR/$CONF" "$CONF_DIR/$CONF"
        done
fi

if [[ $OVERRIDE -eq 0 ]]; then
       for CONF in ${CONF_FILES[*]}; do
                echo "$LOG_MESSAGE generating $CONF file ..."
                sed -i "s/_CONTROLLER_IP_/$CONTROLLER_IP/" $CONF_DIR/$CONF
                sed -i "s/_IMAGE_REF_/$IMAGE_REF/" $CONF_DIR/$CONF
                sed -i "s/_PUBLIC_NETWORK_ID_/$PUBLIC_NETWORK_ID/" $CONF_DIR/$CONF
       done
       echo "$LOG_MESSAGE  ==> done"
fi


echo "Initializing dietstack testing ..." && cd /app && tempest init dietstack

echo "$LOG_MESSAGE starting tempest"
exec "$@"
