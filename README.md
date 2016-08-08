# docker-django-bootstrap
Dockerfile for quickly running Django projects in a Docker container.

Run [Django](https://www.djangoproject.com) projects from source using [Gunicorn](http://gunicorn.org) and [Nginx](http://nginx.org).

## Usage
#### Step 0: Get your Django project in shape
There are a few ways that your Django project needs to be set up in order to be compatible with this Docker image.

**setup.py**  
Your project must have a `setup.py`. All dependencies (including Django itself) need to be listed as `install_requires`.

**Static files**  
Your project's [static files](https://docs.djangoproject.com/en/1.9/howto/static-files/) must be set up as follows:
* `STATIC_URL = '/static/'`
* `STATIC_ROOT` = `BASE_DIR/static` or `BASE_DIR/staticfiles`

**Media files**  
If your project makes use of user-uploaded media files, it must be set up as follows:
* `MEDIA_URL = '/media/'`
* `MEDIA_ROOT` = `BASE_DIR/media` or `BASE_DIR/mediafiles`

***Note:*** Any files stored in directories called `static`, `staticfiles`, `media`, or `mediafiles` in the project root directory will be served by Nginx. Do not store anything here that you do not want the world to see.

#### Step 1: Write a Dockerfile
In the root of the repo for your Django project, add a Dockerfile for the project. For example, this file could contain:
```dockerfile
FROM praekeltfoundation/django-bootstrap
ENV DJANGO_SETTINGS_MODULE "my_django_project.settings"
RUN django-admin collectstatic --noinput
ENV APP_MODULE "my_django_project.wsgi:application"
```

Let's go through these lines one-by-one:
 1. The `FROM` instruction here tells us which image to base this image on. We use the `django-bootstrap` base image.
 2. We set the `DJANGO_SETTINGS_MODULE` environment variable so that Django knows where to find its settings. This is necessary for any `django-admin` commands to work.
 3. *Optional:* If you need to run any build-time tasks, such as collecting static assets, now's the time to do that.
 4. We set the `APP_MODULE` environment variable that will be passed to `gunicorn`, which is installed and run in the `django-bootstrap` base image. `gunicorn` needs to know which WSGI application to run.

The `django-bootstrap` base image actually does a few steps automatically using Docker's `ONBUILD` instruction. It will:
 1. `COPY . /app` - copies the source of your project into the image
 2. `WORKDIR /app` - changes the current working directory to `/app`
 3. `RUN pip install .` - installs your project using `pip`
All these instructions occur directly after the `FROM` instruction in your Dockerfile.

By default, the [`django-entrypoint.sh`](django-entrypoint.sh) script is run when the container is started. This script runs a once-off `django-admin migrate` to update the database schemas and then launches `nginx` and `gunicorn` to run the application.

You can skip the execution of this script and run other commands by overriding the `CMD` instruction. For example, to run a Celery worker, add the following to your Dockerfile:
```dockerfile
CMD ["celery", "worker", \
     "--app", "my_django_project", \
     "--loglevel", "info"]
```

Alternatively, you can override the command at runtime:
```shell
docker run my_django_project_image celery worker --app my_django_project --loglevel info
```

#### Step 2: Add a `.dockerignore` file
Add a file called `.dockerignore` to the root of your project. At a minimum, it should probably contain:
```gitignore
.git
```

Docker uses various caching mechanisms to speed up image build times. One of those mechanisms is to detect if any of the files being `ADD`/`COPY`-ed to the image have changed. You can add a `.dockerignore` file to have Docker ignore changes to certain files. This is conceptually similar to a `.gitignore` file but has different syntax. For more information, see the [Docker documentation](https://docs.docker.com/engine/reference/builder/#dockerignore-file).

It's a good idea to have Docker ignore the `.git` directory because every git operation you perform will result in files changing in that directory (whether you end up in the same state in git as you previously were or not). Also, you probably shouldn't be working with your git repo inside the container.

## Configuration
### Gunicorn
Gunicorn is run with some basic configuration:
* Runs WSGI app defined in `APP_MODULE` environment variable
* Listens on a Unix socket at `/var/run/gunicorn/gunicorn.sock`
* Access logs can be logged to stderr by setting the `GUNICORN_ACCESS_LOGS` environment variable to a non-empty value.

Extra settings can be provided by overriding the `CMD` instruction to pass extra parameters to the entrypoint script. For example:
```dockerfile
CMD ["django-entrypoint.sh", "--threads", "5", "--timeout", "50"]
```

See all the settings available for gunicorn [here](http://docs.gunicorn.org/en/latest/settings.html). A common setting is the number of Gunicorn workers which can be set with the `WEB_CONCURRENCY` environment variable.

### Nginx
Nginx is set up with mostly default config:
* Access logs are sent to stdout, error logs to stderr
* Listens on port 8000 (and this port is exposed in the Dockerfile)
* Serves files from `/static/` and `/media/`
* All other requests are proxied to the Gunicorn socket

Generally you shouldn't need to adjust Nginx's settings. If you do, the configuration files of interest are at:
* `/etc/nginx/nginx.conf`: Main configuration
* `/etc/nginx/conf.d/django.conf`: Proxy configuration
