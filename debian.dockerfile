FROM praekeltfoundation/python-base:debian
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

# Copy in the config files
COPY ./nginx/ /etc/nginx/
COPY ./django-entrypoint.sh /scripts/

EXPOSE 8000

CMD ["django-entrypoint.sh"]

ONBUILD COPY . /app
ONBUILD WORKDIR /app
ONBUILD RUN pip install -e .
