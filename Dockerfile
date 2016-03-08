FROM praekeltfoundation/python-base
MAINTAINER Praekelt Foundation <dev@praekeltfoundation.org>

# Dependencies for psycopg2
RUN apt-get-install.sh libpq5

# Install gunicorn and the entrypoint script
RUN pip install gunicorn
COPY ./django-entrypoint.sh /scripts/
EXPOSE 8000

CMD ["django-entrypoint.sh"]

ONBUILD COPY . /app
ONBUILD WORKDIR /app
ONBUILD RUN pip install -e .
