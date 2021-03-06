FROM praekeltfoundation/python3-base:debian
MAINTAINER Praekelt Foundation <dev@praekeltfoundation.org>

# Install libpq for PostgreSQL support and Nginx to serve everything
# Get Nginx from the upstream repo so that we're up-to-date with Alpine and have
# a compatible config file.
ENV NGINX_VERSION 1.10.1-1~jessie
RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
    && echo "deb http://nginx.org/packages/debian/ jessie nginx" >> /etc/apt/sources.list \
    && apt-get-install.sh \
        libpq5 \
        nginx=${NGINX_VERSION}

# Install gunicorn
RUN pip install gunicorn

# Copy in the Nginx config
COPY ./nginx/ /etc/nginx/
RUN rm /etc/nginx/conf.d/default.conf

# Create gunicorn user and group, make directory for socket, and add nginx user
# to gunicorn group so that it can read/write to the socket.
RUN addgroup gunicorn \
    && adduser --system --ingroup gunicorn gunicorn \
    && mkdir /var/run/gunicorn \
    && chown gunicorn:gunicorn /var/run/gunicorn \
    && adduser nginx gunicorn

# Create celery user and group, make directory for beat schedule file.
RUN addgroup celery \
    && adduser --system --ingroup celery celery \
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
