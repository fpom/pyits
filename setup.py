from distutils.core import setup
from Cython.Build import cythonize
from distutils.extension import Extension
from distutils.command.install import install as _install
from pathlib import Path

import urllib.request, tarfile, ctypes, ctypes.util, os

long_description = Path("README.md").read_text(encoding="utf-8")
description = (long_description.splitlines())[0]


def which_ddd():
    so_name = ctypes.util.find_library("DDD")
    if not so_name:
        return None
    found = []

    class dl_phdr_info(ctypes.Structure):
        _fields_ = [("padding0", ctypes.c_void_p), ("dlpi_name", ctypes.c_char_p)]

    callback_t = ctypes.CFUNCTYPE(
        ctypes.c_int,
        ctypes.POINTER(dl_phdr_info),
        ctypes.POINTER(ctypes.c_size_t),
        ctypes.c_char_p,
    )
    dl_iterate_phdr = ctypes.CDLL("libc.so.6").dl_iterate_phdr
    dl_iterate_phdr.argtypes = [callback_t, ctypes.c_char_p]
    dl_iterate_phdr.restype = ctypes.c_int

    def callback(info, size, data):
        if data in info.contents.dlpi_name:
            found.append(info.contents.dlpi_name)
        return 0

    _ = ctypes.CDLL(so_name)
    dl_iterate_phdr(callback_t(callback), os.fsencode(so_name))
    if found:
        return found[0].decode()
    else:
        return None


import ddd

DDDPATH = which_ddd()
DDDLIB = Path(DDDPATH).parent

print(f"### using {DDDPATH}")

BUILD = Path("build")
ITSURL = "https://lip6.github.io/libITS/linux.tgz"
ITSTGZ = BUILD / "libITS.tgz"
ITSINC = BUILD / "usr/local/include"
ITSLIB = BUILD / "usr/local/lib"

BUILD.mkdir(exist_ok=True)
if not Path(ITSTGZ).exists():
    print(f"downloading {ITSURL!r}")
    with urllib.request.urlopen(ITSURL) as remote, open(ITSTGZ, "wb") as local:
        local.write(remote.read())

with tarfile.open(ITSTGZ) as tar:
    tar.extractall(BUILD)
for path in (BUILD / "usr/local/lib").glob("libDDD.*"):
    path.unlink()


class install(_install):
    def run(self):
        base = Path(self.install_base)
        for tree in ("bin", "include", "lib"):
            self.copy_tree(str(BUILD / "usr/local" / tree), str(base / tree))
        self.mkpath(self.install_lib)
        self.copy_file("its.pxd", self.install_lib)
        self.copy_file("itswrap.h", self.install_lib)
        super().run()


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
    cmdclass={"install": install},
    ext_modules=cythonize(
        [
            Extension(
                "its",
                ["its.pyx"],
                language="c++",
                include_dirs=[str(ITSINC)],
                libraries=["DDD", "antlr3c", "expat", "gmp", "gmpxx"],
                extra_objects=[str(ITSLIB / "libITS.a")],
                library_dirs=[str(ITSLIB), str(DDDLIB)],
                extra_compile_args=["-fno-lto", "-std=c++11"],
                extra_link_args=["-Wl,--no-as-needed"],
            )
        ],
        language_level=3,
    ),
)
