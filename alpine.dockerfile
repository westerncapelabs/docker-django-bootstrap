FROM praekeltfoundation/python3-base:alpine
MAINTAINER Praekelt Foundation <dev@praekeltfoundation.org>

# Install libpq for PostgreSQL support and Nginx to serve everything
RUN apk --no-cache add libpq nginx

# Install gunicorn
RUN pip install gunicorn

# Copy in the Nginx config
COPY ./nginx/ /etc/nginx/

# Create gunicorn user and group, make directory for socket, and add nginx user
# to gunicorn group so that it can read/write to the socket.
RUN addgroup gunicorn \
    && adduser -S -G gunicorn gunicorn \
    && mkdir /var/run/gunicorn \
    && chown gunicorn:gunicorn /var/run/gunicorn \
    && adduser nginx gunicorn

# Create celery user and group, make directory for beat schedule file.
RUN addgroup celery \
    && adduser -S -G celery celery \
    && mkdir /var/run/celery \
    && chown celery:celery /var/run/celery

EXPOSE 8000

COPY ./django-entrypoint.sh /scripts/
CMD ["django-entrypoint.sh"]

WORKDIR /app

ONBUILD COPY . /app
# chown the app directory after copying in case the copied files include
# subdirectories that will be written to, e.g. the media directory
ONBUILD RUN chown -R gunicorn:gunicorn /app
ONBUILD RUN pip install -e .
