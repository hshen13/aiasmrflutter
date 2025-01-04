#!/bin/bash
# wait-for-backend.sh

set -e

host="$1"
shift
cmd="$@"

until curl -f "http://$host/health"; do
  >&2 echo "Backend is unavailable - sleeping"
  sleep 1
done

>&2 echo "Backend is up - executing command"
exec $cmd
