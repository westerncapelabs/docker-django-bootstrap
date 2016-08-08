#!/usr/bin/env sh
set -e

if [ -z "$APP_MODULE" ]; then
  echo "The \$APP_MODULE environment variable must be set to the WSGI application module name"
  exit 1
fi

django-admin migrate --noinput

nginx

# umask working files (worker tmp files & unix socket) as 0o117 (i.e. chmod as
# 0o660) so that they are only read/writable by gunicorn and nginx users.
# Have to specify umask as decimal, not octal (0o117 = 79):
# https://github.com/benoitc/gunicorn/issues/1325
exec gunicorn "$APP_MODULE" \
  --user gunicorn --group gunicorn --umask 79 \
  --bind unix:/var/run/gunicorn/gunicorn.sock \
  ${GUNICORN_ACCESS_LOGS:+--access-logfile -} \
  "$@"
