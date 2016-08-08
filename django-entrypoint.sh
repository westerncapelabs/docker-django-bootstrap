#!/usr/bin/env sh
set -e

if [ -z "$APP_MODULE" ]; then
  echo "The \$APP_MODULE environment variable must be set to the WSGI application module name"
  exit 1
fi

django-admin migrate --noinput

nginx

exec gunicorn "$APP_MODULE" \
  --user django --group django \
  --bind unix:/var/run/gunicorn/gunicorn.sock \
  ${GUNICORN_ACCESS_LOGS:+--access-logfile -} \
  "$@"
