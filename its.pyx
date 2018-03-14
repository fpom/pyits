cimport ddd

from libcpp.string cimport string

##
## ITSModel
##

cdef extern from "its/Type.hh" namespace "its" :
    ctypedef ddd.SDD State
    ctypedef ddd.Shom Transition

cdef extern from "its/ITSModel.hh" namespace "its" :
    cdef cppclass ITSModel :
        ITSModel()
        Transition getNextRel () const
        Transition getPredRel (State reach) const
        State computeReachable (bint wGarbage) const

cdef class itsModel :
    cdef ITSModel *i
