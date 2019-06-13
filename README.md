# koffie
Lightweight and minimalist framework for python web app

<p align="center">
<img src="koffie-logo.png" alt="koffie Logo" height="200"/>
</p>

## Requirements
- libevent
- python 3.7
- c/c++ compiler

## Installation
Install using ```pip```:
```sh
$ pip install koffie
```

## TIPS
```sh
cd development

CFLAGS="-I /usr/local/include -L /usr/local/lib" pipenv install

pipenv run python

Python 3.7.3
>>> import koffie
>>> koffie.run_server()

```