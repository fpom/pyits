import argparse, os.path, sys
from distutils.core import setup
from Cython.Build import cythonize
from distutils.extension import Extension

parser = argparse.ArgumentParser("build.py")
parser.add_argument("-I", metavar="PATH", type=str,
                    default=os.path.expanduser("~/.local/include"),
                    help="libITS source dir containing 'its/ITSModel.hh' "
                    "(default '$HOME/.local/include')")
parser.add_argument("-L", metavar="PATH", type=str,
                    default=os.path.expanduser("~/.local/lib"),
                    help="libITS binary dir (default '$HOME/.local/lib')")
parser.add_argument("-P", metavar="PATH", type=str,
                    default=("../pyddd"),
                    help="pyddd source dir (default '../pyddd')")

args = parser.parse_args()

sys.path.append(args.P)

extensions = [Extension("its",
                        ["its.pyx"],
                        include_dirs = [args.I],
                        libraries = ["ITS"],
                        library_dirs = [args.L],
                        language="c++",
                        extra_compile_args=["-std=c++11"])]

setup(ext_modules=cythonize(extensions, include_path=[args.P]),
      script_args=["build_ext", "--inplace"])

import its
print("built its module in %r" % os.path.relpath(its.__file__))
