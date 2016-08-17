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

# Build example project image
docker build --tag mysite --file "example/$VARIANT.dockerfile" example

# Remove containers and delete the image when script exits
trap "{ set +x; remove_containers; docker rmi -f mysite; }" EXIT

# Launch example project container
docker_run --name mysite -p 8000:8000 mysite

# Simple check to see if the site is up
curl -fsL http://localhost:8000/admin | fgrep '<title>Log in | Django site admin</title>'

# Check that we can get a static file served by Nginx
curl -fsL http://localhost:8000/static/admin/css/base.css | fgrep 'DJANGO Admin styles'

# Check that if we say we support gzip, then Nginx gives us that
curl -fIH 'Accept-Encoding: gzip' http://localhost:8000/static/admin/css/base.css \
  | fgrep -e 'Content-Encoding: gzip' \
          -e 'Vary: Content-Encoding'

# Check that if we fetch a filetype that shouldn't be gzipped, then it isn't
curl -fIH 'Accept-Encoding: gzip' http://localhost:8000/static/admin/fonts/Roboto-Light-webfont.woff \
  | fgrep -v 'Content-Encoding: gzip' \
  | fgrep 'Content-Type: application/font-woff'


# Celery tests
# ############
# Start a RabbitMQ broker
docker_run --name celery-rabbitmq rabbitmq

# Start a new django-bootstrap container linked to the broker
# (set the container's hostname so that Celery's logs are easier to grep)
docker_run --name mysite-celery \
  --hostname mysite-celery \
  --link celery-rabbitmq:rabbitmq \
  -e CELERY_APP=mysite \
  -e CELERY_BROKER=amqp://rabbitmq:5672 \
  -e CELERY_BEAT=1 \
  mysite

# Check the logs to see if the Celery worker started up successfully
docker logs mysite-celery 2>&1 | fgrep 'celery@mysite-celery ready'

# Check the logs to see if Celery beat started up successfully
docker logs mysite-celery 2>&1 | fgrep 'beat: Starting...'

set +x
echo
echo "PASSED"
