import os
from setuptools import setup, find_packages
from distutils.extension import Extension
from Cython.Build import cythonize

def read(fname):
    """Read a file and return its content."""
    with open(os.path.join(os.path.dirname(__file__), fname)) as f:
        return f.read()

setup(
    name="koffie",
    version="0.1.0",
    description="Lightweight and minimalist framework for python web app",
    long_description=read("README.md"),
    long_description_content_type="text/markdown",
    packages=find_packages(exclude=[]),
    install_requires=[
        "cython"
    ],
    extras_require={
    },
    setup_requires=[],
    tests_require=[],
    ext_modules = cythonize([Extension("koffie._koffie", ["koffie/_koffie.pyx"], language="c", libraries=["event", "event_openssl", "ssl", "crypto"])], language_level="3", gdb_debug=True)
)