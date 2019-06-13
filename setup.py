import os
from setuptools import setup, find_packages
from distutils.extension import Extension

def read(fname):
    """Read a file and return its content."""
    with open(os.path.join(os.path.dirname(__file__), fname)) as f:
        return f.read()

setup(
    name="coffee",
    version="1.0.0",
    description="Lightweight and minimalist framework for python web app",
    long_description=read("README.md"),
    packages=find_packages(exclude=[]),
    install_requires=[
        "cython"
    ],
    extras_require={
    },
    setup_requires=[],
    tests_require=[],
    ext_modules = [Extension("coffee._coffee", ["coffee/_coffee.pyx"], language="c", libraries=["event"])]
)