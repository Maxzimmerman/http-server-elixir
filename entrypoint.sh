#!/bin/bash
set -e

echo "Starting app..."
exec /app/codecrafters_http_server "$@"
