#!/bin/bash

sudo su
yum install -y python-pip
pip install virtualenv
pip install --upgrade pip
mkdir ~/myproject && cd ~/myproject
virtualenv myprojectenv
source myprojectenv/bin/activate
pip install django psycopg2
django-admin.py startproject myproject .
#vim ~/myproject/myproject/settings.py
#below cannot be sed or perled in
perl -i -pe 's/DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}/DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'myproject',
        'USER': 'myprojectuser',
        'PASSWORD': 'password',
        'HOST': 'postgres-b',
        'PORT': '5432',
    }
}/g' ~/myproject/myproject/settings.py
python manage.py makemigrations
python manage.y migrate
