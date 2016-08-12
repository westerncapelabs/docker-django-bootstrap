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

CONTAINERS=()
function docker_run {
  # Run a detached container temporarily for tests. Removes the container when
  # the script exits and sleeps a bit to wait for it to start.
  local container
  container="$(docker run -d "$@")"
  CONTAINERS+=("$container")
  sleep 5
}

function remove_containers {
  echo "Stopping and removing containers..."
  for container in "${CONTAINERS[@]}"; do
    docker stop "$container"
    docker rm -f "$container"
  done
}

# Build example project image, run and wait for it to start
docker build --tag mysite --file "example/$VARIANT.dockerfile" example
docker_run --name mysite -p 8000:8000 mysite

# Delete remove containers and delete the image
trap "remove_containers; docker rmi -f mysite" EXIT

# Simple check to see if the site is up
curl -fsL http://localhost:8000/admin | fgrep '<title>Log in | Django site admin</title>'

# Check that we can get a static file served by Nginx
curl -fsL http://localhost:8000/static/admin/css/base.css | fgrep 'DJANGO Admin styles'
