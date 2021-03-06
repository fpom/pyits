A Python binding for libITS
===========================

(C) 2018 Franck Pommereau <franck.pommereau@univ-evry.fr>

This library provides a Python binding for libITS https://github.com/lip6/libITS

## Requirements

 - Python 3 (tested with 3.5.2), this binding is not expected to work
   with Python 2
 - Cython (tested with 0.27.3)

libITS (tested with 1.9.0) will be automatically downloaded and installed
during the installation

## Installation

Run `python setup.py install` as usual.

You may check the doctests in the module by running `python3 test.py`,
which should produce no output if everything goes well.

## Licence

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.

You have received a copy of the GNU Lesser General Public License
along with this program, see file COPYING or
http://www.gnu.org/licenses
