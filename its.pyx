from ddd cimport sdd, makesdd, shom, makeshom, Shom
from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.pair cimport pair
from libcpp.list cimport list

import os.path, os, warnings, functools, operator, sys

##
## ITSModel
##

cdef extern from "its/Options.hh" namespace "its" :
    bint handleInputOptions(vector[const char*] &args, ITSModel &model)

cdef class model :
    def __init__ (model self, str path, str fmt="") :
        """
        >>> m = model(",t.gal")
        >>> next(iter(m.initial().items()))
        {'#0': [{...}]}
        """
        if not fmt :
            fmt = os.path.splitext(path)[1].strip(".").upper()
        if fmt not in ["CAMI", "PROD", "ROMEO", "UROMEO", "ITSXML", "ETF",
                       "DLL", "NDLL", "DVE", "GAL", "CGAL", "AIGER"] :
            raise ValueError("unsupported input format %r" % fmt)
        self.path = path
        self.fmt = fmt
        self.i = ITSModel()
        cdef vector[const char*] args = [b"-t", fmt.encode(), b"-i", path.encode()]
        handleInputOptions(args, self.i)
    cpdef sdd initial (model self) :
        """
        >>> m = model(",t.gal")
        >>> next(iter(m.initial().items()))
        {'#0': [{...'Ac': 1...}]}
        """
        return makesdd(self.i.getInitialState())
    def reachable (model self, verbose=None) :
        """
        >>> m = model(",t.gal")
        >>> len(m.reachable())
        109
        """
        cdef sdd prev
        cdef sdd succ
        cdef shom trans
        if verbose is None :
            return makesdd(self.i.computeReachable(True))
        prev = self.initial()
        succ = sdd.empty()
        trans = self.succ() | shom.ident()
        while True :
            if verbose(len(prev)) :
                break
            succ = trans(prev)
            if succ == prev :
                break
            prev = succ
        return succ
    cpdef shom succ (model self) :
        return makeshom(self.i.getNextRel())
    cpdef shom pred (model self) :
        cdef msg = []
        cdef int r, w, s
        cdef shom ret
        cdef str warn
        r, w = os.pipe()
        s = os.dup(2)
        os.dup2(w, 2)
        ret = makeshom(self.i.getPredRel())
        os.write(w, b"#EOF#")
        while msg[-5:] != [b"#", b"E", b"O", b"F", b"#"] :
            msg.append(os.read(r, 1))
        os.dup2(s, 2)
        if len(msg) > 5 :
            warn = b"".join(msg[:-5]).decode().strip()
            # TODO: use a custom Warning class to enable easier filtering
            if "Faster fixpoint algorithm enabled." not in warn :
                warnings.warn(warn, RuntimeWarning)
        return ret
    cpdef dict transitions (model self) :
        cdef Type.namedTrs_t name2shom
        cdef dict d = {}
        self.i.getNamedLocals(name2shom)
        for p in name2shom :
            d[p.first.decode()] = makeshom(Shom(p.second))
        return d
    def observe (self, variables) :
        cdef vector[string] v
        cdef int i
        cdef str n
        cdef pType t
        v.resize(len(variables))
        for i, n in enumerate(variables) :
            v[i] = n.encode()
        t = self.i.getInstance().getType()
        return makeshom(t.observe(v, self.i.computeReachable(True)))
