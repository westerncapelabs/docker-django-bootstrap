FROM praekeltfoundation/django-bootstrap:debian
ENV DJANGO_SETTINGS_MODULE "mysite.settings"
ENV APP_MODULE "mysite.wsgi:application"
