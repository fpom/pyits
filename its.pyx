from ddd cimport sdd, makesdd, SDD, shom, makeshom, Shom
from libcpp.string cimport string
from libcpp.vector cimport vector

import os.path

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

cdef extern from "its/ITSModel.hh" namespace "its" :
    cdef cppclass ITSModel :
        ITSModel()
        Shom getNextRel () const
        Shom getPredRel () const

cdef extern from "its/Options.hh" namespace "its" :
    bint handleInputOptions(vector[const char*] &args, ITSModel &model)

cdef extern from "itswrap.h" :
    SDD* getInitialState_ptr(ITSModel *i)
    SDD* computeReachable_ptr (ITSModel *i, bint wGarbage)
    Shom *getNextRel (ITSModel i)
    Shom *getNextRel (ITSModel i)
    Shom *getPredRel (ITSModel i)

cdef class model :
    cdef ITSModel *i
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
        self.i = new ITSModel()
        handleInputOptions(args, self.i[0])
    cpdef sdd initial (model self) :
        """
        >>> m = model(",t.gal")
        >>> next(iter(m.initial().items()))
        {'#0': [{...'Ac': 1...}]}
        """
        return makesdd(getInitialState_ptr(self.i))
    cpdef sdd reachable (model self) :
        """
        >>> m = model(",t.gal")
        >>> len(m.reachable())
        109
        """
        return makesdd(computeReachable_ptr(self.i, True))
    cpdef shom succ (model self) :
        return makeshom(getNextRel(self.i[0]))
    cpdef shom pred (model self) :
        return makeshom(getPredRel(self.i[0]))
    cpdef sdd deadlocks (model self) :
        cdef sdd reach = self.reachable()
        cdef shom pred = self.pred()
        return reach - pred(reach)
    cpdef sdd scc_union (model self) :
        cdef sdd s = self.reachable()
        cdef sdd q = sdd.empty()
        cdef shom pred = self.pred()
        cdef shom succ = self.succ()
        while s != q :
            q = s
            s = succ(s) & q
            q = s
            s = pred(s) & q
        return s
    def scc (model self) :
        cdef sdd sub = self.scc_union()
        cdef sdd node, comp
        cdef shom succs = (self.succ() & sub).star()
        cdef shom preds = (self.pred() & sub).star()
        while sub :
            node = sub.pick()
            comp = succs(node) & preds(node)
            yield comp
            sub = sub - comp
