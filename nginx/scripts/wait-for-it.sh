#!/bin/bash
# Optimized wait-for-it script for Docker

host=$1
port=$2
shift 2
cmd="$@"

echo "Waiting for $host:$port..."
while ! nc -z "$host" "$port" 2>/dev/null; do
  sleep 1
done

echo "$host:$port is available"
exec $cmd
