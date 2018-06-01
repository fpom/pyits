from ddd cimport sdd, makesdd, shom, makeshom, Shom
from libcpp.string cimport string
from libcpp.vector cimport vector
from libcpp.pair cimport pair
from libcpp.list cimport list

import os.path, os, warnings, functools, operator

##
## ITSModel
##

cdef extern from "its/gal/GAL.hh" namespace "its" :
    cdef cppclass GAL :
        string getName ()

cdef extern from "its/gal/parser/GALParser.hh" namespace "its" :
    cdef cppclass GALParser :
        @staticmethod
        GAL* loadGAL (const string &filename)

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
        cdef vector[const char*] args = [b"-t", fmt.encode(), b"-i", path.encode()]
        self.i = ITSModel()
        handleInputOptions(args, self.i)
    cpdef sdd initial (model self) :
        """
        >>> m = model(",t.gal")
        >>> next(iter(m.initial().items()))
        {'#0': [{...'Ac': 1...}]}
        """
        return makesdd(self.i.getInitialState())
    cpdef sdd reachable (model self) :
        """
        >>> m = model(",t.gal")
        >>> len(m.reachable())
        109
        """
        return makesdd(self.i.computeReachable(True))
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
            if "Faster fixpoint algorithm enabled." not in warn :
                warnings.warn(warn, RuntimeWarning)
        return ret
    cpdef sdd deadlocks (model self) :
        cdef sdd reach = self.reachable()
        cdef shom pred = self.pred()
        return reach - pred(reach)
    cpdef set scc (model self) :
        cdef set scc, refined
        cdef sdd sub, node, s, p, i, r
        cdef sdd empty = sdd.empty()
        cdef shom sccpred = self.succ.gfp()
        cdef shom sccsucc = self.pred.gfp()
        cdef shom succ = self.succ.lfp()
        cdef shom pred = self.pred.lfp()
        scc = {sccpred(self.reachable()) & sccsucc(self.reachable())}
        while True :
            refined = set()
            for sub in scc :
                node = sub.pick()
                s = succ(node) & sub
                p = pred(node) & sub
                i = s & p
                r = sub - (s | p)
                s -= i
                p -= i
                refined.add(sccpred(i) & sccsucc(i))
                refined.add(sccpred(s) & sccsucc(s))
                refined.add(sccpred(p) & sccsucc(p))
                refined.add(sccpred(r) & sccsucc(r))
            refined.discard(empty)
            if refined == scc :
                break
            scc = refined
        return scc
    cpdef sdd scc_union (model self) :
        return functools.reduce(operator.or_, self.scc(), sdd.empty())
    cpdef dict transitions (model self) :
        cdef Type.namedTrs_t name2shom
        cdef dict d = {}
        self.i.getNamedLocals(name2shom)
        for p in name2shom :
            d[p.first.decode()] = makeshom(Shom(p.second))
        return d
