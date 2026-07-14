#!/bin/sh
# /docker-entrypoint-initdb.d/init-db.sh
# Runs once on first startup. All values come from runtime environment.

set -e

# Fail fast if any required secret is missing
for var in MYSQL_ROOT_PASSWORD MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE; do
  if [ -z "$var" ]; then
    echo "ERROR: $var is not set. Secrets must be provided at runtime."
    exit 1
  fi
done

cat <<EOF > /tmp/init.sql
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < /tmp/init.sql
rm -f /tmp/init.sql
