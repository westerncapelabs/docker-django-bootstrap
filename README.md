# docker-django-bootstrap
Dockerfile for quickly running Django projects in a Docker container.

Run [Django](https://www.djangoproject.com) projects from source using [gunicorn](http://gunicorn.org).

## Usage
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

By default, the [`django-entrypoint.sh`](django-entrypoint.sh) script is run when the container is started. This script runs a once-off `django-admin migrate` to update the database schemas and then launches `gunicorn` to run the application.

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

#### Step 3: Use a static file serving middleware *(optional but recommended)*
Choose one of the following projects to use to serve static files:
* [DJ-Static](https://github.com/kennethreitz/dj-static)
* [WhiteNoise](http://whitenoise.evans.io)

Serving static files using Django is generally not advised due to performance issues. In pre-Docker land, we would normally use something like Nginx to serve all the static files at the `/static/` path. But with Docker (and Seed Stack), we're not necessarily sure where our containers are running and their filesystems are fairly isolated from the outside world. We'd also like to keep to running a single process in each Docker container and running Nginx inside a container gets a bit complicated.
