FROM praekeltfoundation/django-bootstrap:debian
ENV DJANGO_SETTINGS_MODULE "mysite.settings"
RUN django-admin collectstatic --noinput
ENV APP_MODULE "mysite.wsgi:application"
