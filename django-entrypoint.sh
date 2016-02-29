#!/bin/bash -e

django-admin migrate

exec gunicorn \
    --bind :8000 \
    --workers 2 \
    --access-logfile - \
    "$@"
