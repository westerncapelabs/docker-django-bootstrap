FROM praekeltfoundation/python-base:alpine
MAINTAINER Praekelt Foundation <dev@praekeltfoundation.org>

# Install libpq for PostgreSQL support and Nginx to serve everything
RUN apk --no-cache add libpq nginx

# Install gunicorn
RUN pip install gunicorn

# Copy in the Nginx config
COPY ./nginx/ /etc/nginx/

RUN addgroup django \
    && adduser -S -G django django \
    && mkdir /var/run/gunicorn \
    && chown django:django /var/run/gunicorn

EXPOSE 8000

COPY ./django-entrypoint.sh /scripts/
CMD ["django-entrypoint.sh"]

WORKDIR /app

ONBUILD COPY . /app
# chown the app directory after copying in case the copied files include
# subdirectories that will be written to, e.g. the media directory
ONBUILD RUN chown -R django:django /app
ONBUILD RUN pip install -e .
