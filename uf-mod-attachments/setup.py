#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import unicode_literals

import os
import re
import sys

from setuptools import setup

install_requires = [
    'psycopg2',
]

v=0.1

setup(
    name='uf-mod-attachments',
    version=v,
    description='Unifield loader',
    url='http://www.msf.org/',
    author='MSF',
    license='MIT License',
    include_package_data=True,
    install_requires=install_requires,
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Environment :: Console',
        'Intended Audience :: Customer Service',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
    ],
)
