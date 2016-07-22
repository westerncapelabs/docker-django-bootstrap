#!/usr/bin/env sh
set -e

django-admin migrate --noinput

if [ -z "$APP_MODULE" ]; then
  echo "The \$APP_MODULE environment variable must be set to the WSGI application module name"
  exit 1
fi

nginx

exec gunicorn "$APP_MODULE" \
    --bind unix:/var/run/gunicorn.sock \
    --access-logfile - \
    "$@"
