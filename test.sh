#!/usr/bin/env bash
set -e

function usage() {
  echo "Usage: $0 VARIANT"
  echo "  VARIANT is the type of django-bootstrap image to test"
}

VARIANT="$1"
shift || { usage >&2; exit 1; }
trap '{ set +x; echo; echo FAILED; echo; } >&2' ERR

set -x

# Build example project image, run and wait for it to start
docker build --tag mysite --file "example/$VARIANT.dockerfile" example
docker run --detach --name mysite -p 8000:8000 mysite
trap "docker stop mysite; docker rm -f mysite; docker rmi -f mysite" EXIT
sleep 5

# Simple check to see if the site is up
curl -fsL http://localhost:8000/admin | fgrep '<title>Log in | Django site admin</title>'

# Check that we can get a static file served by Nginx
curl -fsL http://localhost:8000/static/admin/css/base.css | fgrep 'DJANGO Admin styles'