from setuptools import setup

setup(
    name="mysite",
    version="0.1",
    author='Praekelt Foundation',
    author_email='dev@praekeltfoundation.org',
    install_requires=[
        'celery >=3.1,<4.0',
        'Django >=1.10,<1.11',
        'django-reversion',
    ],
)
