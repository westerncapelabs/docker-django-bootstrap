FROM praekeltfoundation/python-base:debian
MAINTAINER Praekelt Foundation <dev@praekeltfoundation.org>

# Install libpq for PostgreSQL support and Nginx to serve everything
RUN apt-get-install.sh libpq5 nginx-light

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
