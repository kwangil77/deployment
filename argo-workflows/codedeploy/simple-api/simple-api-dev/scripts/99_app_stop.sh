#!/bin/bash
if [ -f "/var/app/current/docker-compose.yml" ]; then
    cd /var/app/current && docker-compose down
fi