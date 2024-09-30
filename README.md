# A Python binding for libITS

(C) 2018 [Franck Pommereau](franck.pommereau@univ-evry.fr)

This library provides a Python binding for [libITS](https://github.com/lip6/libITS).

## Requirements

- Python 3
- Cython
- G++ v.11 (does not work with clang)
- [pyddd](https://github.com/fpom/pyddd)
- libITS (see below)

G++ version 11 is needed to ensure compatibility with precompiled binaries
(otherwise, compilation will fail with `lto1` complaining avout incompatible
bytecode streams).

## Installation

First, `libITS` needs to be installed. Because it uses very tricky
compilation options, a suitable precompiled version is
[provided here](https://github.com/fpom/pyddd/raw/master/libITS.tar.gz).
It contains two directories: `lib` and `include` that should be copied
so that `ld` will find `lib/libITS.a`. Installation will assume that
both directories reside together into the same location.

Directories `lib` and `include` should be merged with those coming from
the installation of [pyddd](https://github.com/fpom/pyddd) as detecting
`lib/libDDD.so` will be used to know where `lib/libITS.a` resides.
Please follow the same installation procedure as described in
[pyddd/README.md](https://github.com/fpom/pyddd/blob/master/README.md),
using `libITS.tar.gz` instead of `libDDD.tar.gz`.

Then, run `pip install git+https://github.com/fpom/pyits`, or if you
cloned the repository, `cd pyits && pip install .`. You may check the
doctests in the module by running `python3 test.py`, which should
produce no output if everything goes well.

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
