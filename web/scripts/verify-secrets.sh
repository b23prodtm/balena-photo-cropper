#!/usr/bin/env sh
set -eu

service="${1:-web}"

echo "[verify-secrets] service=${service}"
if [ -d /run/secrets ]; then
  ls -l /run/secrets || true
else
  echo "[verify-secrets] /run/secrets not present"
fi

case "$service" in
  web)
    for k in SECURITY_SALT DB_PASSWORD DB_TEST_PASSWORD EMAIL_PASSWORD; do
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
    ;;
  *)
    echo "[verify-secrets] INFO: no web-specific checks for service=$service"
    ;;
esac

exit 0
