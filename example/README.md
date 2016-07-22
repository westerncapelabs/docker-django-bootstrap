# mysite
Example Django project for testing. Generated using
```shell
django-admin startproject mysite
```
... with a `setup.py` added so that Django is installed.

## Usage
Build the image:
```shell
DOCKERFILE=alpine.dockerfile
docker build -t mysite -f $DOCKERFILE .
```

Start the container:
```shell
docker run --rm -it -p 8000:8000 mysite
```

Finally, open http://localhost:8000 in your browser.
