#!/bin/bash

# Start SSH service in the background
# -D: don't detach from controlling terminal (important for supervisord or entrypoint)
# -e: log to stderr
/usr/sbin/sshd -D -e &

# Start NGINX service in the background (uncomment if you uncommented NGINX in Dockerfile)
# service nginx start &

# Run nvidia-smi (optional, if you want it to run before Jupyter)
nvidia-smi

# Execute Jupyter Lab as the main process
# `exec` replaces the current shell with the specified command,
# ensuring signals (like Ctrl+C) are handled correctly by Jupyter Lab.
exec jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --allow-root \
    --no-browser \
    --ServerApp.allow_origin='*' \
    --ServerApp.allow_origin_pat='.*' \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.root_dir='/workspace'
