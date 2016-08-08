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
ONBUILD RUN pip install -e .
