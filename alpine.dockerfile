FROM praekeltfoundation/python-base:alpine
MAINTAINER Praekelt Foundation <dev@praekeltfoundation.org>

# Install libpq for PostgreSQL support and Nginx to serve everything
RUN apk --no-cache add libpq nginx

# Install gunicorn
RUN pip install gunicorn

# Copy in the Nginx config
COPY ./nginx/ /etc/nginx/

EXPOSE 8000

COPY ./django-entrypoint.sh /scripts/
CMD ["django-entrypoint.sh"]

ONBUILD COPY . /app
ONBUILD WORKDIR /app
ONBUILD RUN pip install -e .
