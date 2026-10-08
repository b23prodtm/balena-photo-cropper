#!/usr/bin/env sh
set -eu

echo "[verify-secrets] service=mysqldb"
if [ -d /run/secrets ]; then
  ls -l /run/secrets || true
fi

for k in MYSQL_PASSWORD MYSQL_ROOT_PASSWORD; do
  f_var="${k}_FILE"
  eval f_val=\${$f_var:-}
  eval v_val=\${$k:-}
  if [ -n "${f_val:-}" ]; then
    if [ -r "$f_val" ]; then
      echo "[verify-secrets] OK: $f_var -> readable file"
    else
      echo "[verify-secrets] WARN: $f_var set but unreadable: $f_val"
    fi
  elif [ -n "${v_val:-}" ]; then
    echo "[verify-secrets] OK: $k set"
  else
    echo "[verify-secrets] WARN: neither $k nor $f_var set"
  fi
done

exit 0
