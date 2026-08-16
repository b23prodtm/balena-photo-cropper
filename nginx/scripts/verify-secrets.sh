#!/usr/bin/env sh
set -eu

echo "[verify-secrets] service=nginx"
if [ -d /run/secrets ]; then
  ls -l /run/secrets || true
fi

for f in /run/secrets/ssl_key /run/secrets/ssl_crt; do
  if [ -r "$f" ]; then
    echo "[verify-secrets] OK: readable $f"
  else
    echo "[verify-secrets] WARN: missing/unreadable $f"
  fi
done

exit 0
