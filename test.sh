#!/usr/bin/env bash
set -e

function usage() {
  echo "Usage: $0 IMAGE_TAG"
  echo "  IMAGE_TAG is the Docker image tag for the django-bootstrap image to test"
}

IMAGE_TAG="$1"
shift || { usage >&2; exit 1; }

TAG="${IMAGE_TAG##*:}"

# Build example project image, run and wait for it to start
docker build --tag mysite --file "example/$TAG.dockerfile" example
docker run --detach --name mysite -p 8000:8000 mysite
sleep 5

# Simple check to see if the site is up
curl -fsL http://localhost:8000/admin | fgrep '<title>Log in | Django site admin</title>'

# Check that we can get a static file served by Nginx
curl -fsL http://localhost:8000/static/admin/css/base.css | fgrep 'DJANGO Admin styles'
docker stop mysite
