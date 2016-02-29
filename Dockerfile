FROM praekeltfoundation/python-base
MAINTAINER Praekelt Foundation <dev@praekeltfoundation.org>

# Dependencies for psycopg2
RUN apt-get-install.sh libpq5

# Install gunicorn and the entrypoint script
RUN pip install gunicorn
COPY ./django-entrypoint.sh /scripts/
EXPOSE 8000

ENTRYPOINT ["eval-args.sh", "dinit", "django-entrypoint.sh"]
# Reset CMD to not be 'python'
CMD []

ONBUILD COPY . /app
ONBUILD WORKDIR /app
ONBUILD RUN pip install .
