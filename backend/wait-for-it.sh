#!/usr/bin/env sh
# wait-for-it.sh

set -e

# Extract host and port from first argument
hostport="$1"
shift
host=$(echo "$hostport" | cut -d: -f1)
port=$(echo "$hostport" | cut -d: -f2)

# Skip the "--" argument
shift

# Get database credentials from environment variables
DB_USER=${POSTGRES_USER:-aiasmr}
DB_PASSWORD=${POSTGRES_PASSWORD:-aiasmr}
DB_NAME=${POSTGRES_DB:-aiasmr}

# The remaining arguments form the command to execute
cmd="$@"

# Function to check if postgres is ready
check_postgres() {
    PGPASSWORD=$DB_PASSWORD psql -h "$host" -p "$port" -U "$DB_USER" -d "$DB_NAME" -c '\q' >/dev/null 2>&1
}

# Wait for postgres to be ready
echo "Waiting for PostgreSQL to be ready at $host:$port..."
until check_postgres; do
    echo >&2 "PostgreSQL is unavailable - sleeping"
    sleep 1
done

echo "PostgreSQL is up - executing command: $cmd"
exec $cmd
