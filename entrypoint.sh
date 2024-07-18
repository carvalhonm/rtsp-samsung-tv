#!/bin/bash

# Ensure WS_PORT is set from environment or use default
export WS_PORT=${WS_PORT:-9999}

# Start the application with PM2, passing the environment variables
pm2 start $(npm root -g)/rtsp-samsung-tv/server.js --env production --name rtsp-samsung-tv

# Keep the container running and log output
tail -f ~/.pm2/logs/server-error.log
