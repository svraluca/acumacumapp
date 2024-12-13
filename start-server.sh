#!/bin/bash
while true; do
    echo "Starting server..."
    node server.js
    echo "Server crashed, restarting in 5 seconds..."
    sleep 5
done
