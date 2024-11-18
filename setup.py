import os
import site
import tarfile

from pathlib import Path

from distutils.core import setup
from setuptools.command.install import install
from distutils.extension import Extension
from Cython.Build import cythonize


##
## install libITS
##


class InstallITS(install):
    # install libITS together with Python package
    def run(self):
        super().run()
        with tarfile.TarFile.open("libITS.tar.gz") as tar:
            tar.extractall(self.install_base, filter="fully_trusted")


# install libITS lcoally for build
ITSBASE = Path("libITS").absolute()
with tarfile.TarFile.open("libITS.tar.gz") as tar:
    tar.extractall(ITSBASE, filter="fully_trusted")
ITSLIB = ITSBASE / "lib"
ITSINC = ITSBASE / "include"
os.environ["LD_LIBRARY_PATH"] = str(ITSLIB)
os.environ["CXX"] = "g++"

##
## setup
##

long_description = Path("README.md").read_text(encoding="utf-8")
description = (long_description.splitlines())[0]

setup(
    name="pyits",
    description=description,
    long_description=long_description,
    url="https://github.com/fpom/pyits",
    author="Franck Pommereau",
    author_email="franck.pommereau@univ-evry.fr",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Topic :: Scientific/Engineering",
        "License :: OSI Approved :: GNU Lesser General Public License v3 (LGPLv3)",
        "Programming Language :: Python :: 3",
        "Operating System :: OS Independent",
    ],
    packages=[],
    ext_modules=cythonize(
        [
            Extension(
                "its",
                ["its.pyx"],
                language="c++",
                include_dirs=[str(ITSINC)],
                libraries=["DDD", "antlr3c", "expat", "gmp", "gmpxx"],
                extra_objects=[str(ITSLIB / "libITS.a")],
                library_dirs=[str(ITSLIB)],
                extra_compile_args=["-std=c++11"],
                extra_link_args=["-Wl,--no-as-needed"],
            )
        ],
        language_level=3,
    ),
    data_files=[(site.getsitepackages(".")[0], ["its.pxd"])],
)
