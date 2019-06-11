import os
from setuptools import setup, find_packages
from distutils.extension import Extension
from Cython.Build import cythonize

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
        "cython==0.29.7"
    ],
    extras_require={
        "dev": [
        ]
    },
    setup_requires=[],
    tests_require=[],
    ext_modules = [Extension("coffee", ["coffee.pyx"], language="c", libraries=["event"])]
)