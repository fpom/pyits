from distutils.core import setup
from Cython.Build import cythonize
from distutils.extension import Extension
from distutils.command.install import install as _install
from pathlib import Path

import urllib.request, tarfile, shutil, os, subprocess, tempfile

import ddd

long_description = Path("README.md").read_text(encoding="utf-8")
description = (long_description.splitlines())[0]

BUILD = Path(tempfile.mktemp())
ITSINC = str(BUILD / "libITS-bin/local/include")
ITSLIB = str(BUILD / "libITS-bin/local/lib")

DDDLIB = str(Path(ddd.__file__).parent)

def copy (src, tgt, verbose=True) :
    if verbose :
        print(src, "->", tgt)
    shutil.copy2(src, tgt)

def copytree (src, tgt, verbose=True) :
    if not tgt.exists() :
        if verbose :
            print(src, "->", tgt)
        tgt.mkdir(exist_ok=True, parents=True)
    for child in src.iterdir() :
        if child.is_dir() :
            copytree(child, tgt / child.name, verbose)
        elif child.is_symlink() :
            _tgt = tgt / child.name
            if not _tgt.exists() :
                if verbose :
                    print(child, "->", _tgt)
                link = os.readlink(str(child))
                _tgt.symlink_to(link)
        elif child.is_file() :
            _tgt = tgt / child.name
            if not _tgt.exists() :
                copy(str(child), str(_tgt), verbose)

BUILD.mkdir(exist_ok=True)
for url, name in [("https://lip6.github.io/libITS/linux.tgz",
                   "libITS-bin.tgz"),
                  ("https://github.com/lip6/libITS/archive/master.tar.gz",
                   "libITS-git.tgz"),
                  ("https://github.com/lip6/libITS/raw/gh-pages/itsreach-0.2.20220428124359.tar.gz",
                   "libITS-src.tgz")] :
    print(f"downloading {url!r}")
    with urllib.request.urlopen(url) as remote, \
         (BUILD / name).open("wb") as local :
        local.write(remote.read())
    with tarfile.open(BUILD / name) as tar :
        tar.extractall(BUILD)
        root = BUILD / next(iter(tar)).name
        root.rename((BUILD / name).with_suffix(""))
copytree(BUILD / "libITS-git", BUILD / "libITS-src", False)
ITSLOC = (BUILD / "libITS-bin" / "local").absolute()
print("building libITS")
subprocess.check_call(["./configure", "--with-pic", "--enable-shared",
                       f"--with-libddd={ITSLOC}",
                       f"--with-antlrjar={ITSLOC}/lib/antlr-3.4-complete.jar",
                       f"--with-libexpat={ITSLOC}",
                       f"--with-antlrc={ITSLOC}",
                       f"--with-gmp={ITSLOC}"],
                      cwd=f"{BUILD}/libITS-src",
                      env=dict(os.environ,
                               CPPFLAGS=f"-I{ITSLOC}/include",
                               LDFLAGS=f"-L{ITSLOC}/lib"))
subprocess.check_call(["make"], cwd=f"{BUILD}/libITS-src")
copy(str(BUILD / "libITS-src/lib/libITS.a"),
     str(BUILD / "libITS-bin/local/lib/libITS.a"))

class install (_install) :
    def run (self) :
        super().run()
        base = Path(self.install_base)
        for tree in ("bin", "include", "lib") :
            copytree(BUILD / "libITS-bin/local" / tree, base / tree)
        for path, names in [(Path(self.install_lib), ["its.pxd", "itswrap.h"])] :
            path.mkdir(exist_ok=True, parents=True)
            for name in names :
                copy(name, path / name)

setup(name="pyits",
      description=description,
      long_description=long_description,
      url="https://github.com/fpom/pyits",
      author="Franck Pommereau",
      author_email="franck.pommereau@univ-evry.fr",
      classifiers=["Development Status :: 4 - Beta",
                   "Intended Audience :: Developers",
                   "Topic :: Scientific/Engineering",
                   "License :: OSI Approved :: GNU Lesser General Public License v3 (LGPLv3)",
                   "Programming Language :: Python :: 3",
                   "Operating System :: OS Independent"],
      ext_modules=cythonize([Extension("its",
                                       ["its.pyx"],
                                       include_dirs = [ITSINC],
                                       libraries = ["DDD", "antlr3c", "expat",
                                                    "gmp", "gmpxx"],
                                       extra_objects=[str(Path(ITSLIB) / "libITS.a")],
                                       library_dirs = [ITSLIB],
                                       language="c++",
                                       extra_compile_args=["-std=c++11"])],
                            include_path=[DDDLIB],
                            language_level=3),
      cmdclass={"install" : install},
)

shutil.rmtree(BUILD)
