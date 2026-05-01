#!/bin/sh
set -e

# Substitute TURN_SERVER_TOKEN safely
sed "s|\${TURN_SERVER_TOKEN}|${TURN_SERVER_TOKEN}|g" \
    /etc/coturn/turnserver.conf.template > /tmp/turnserver.conf

# Start coturn
exec turnserver -c /tmp/turnserver.conf