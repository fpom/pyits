from ddd cimport sdd, shom, Shom
from libcpp.string cimport string
from libcpp.pair cimport pair
from libcpp.list cimport list

cdef extern from "its/Type.hh" namespace "its" :
    cdef cppclass Type :
        ctypedef pair[string,Shom] namedTr_t
        ctypedef list[namedTr_t] namedTrs_t

cdef extern from "its/ITSModel.hh" namespace "its" :
    cdef cppclass ITSModel :
        ITSModel()
        void getNamedLocals (Type.namedTrs_t &ntrans) const

cdef class model :
    cdef ITSModel *i
    cpdef sdd initial (model self)
    cpdef sdd reachable (model self)
    cpdef shom succ (model self)
    cpdef shom pred (model self)
    cpdef sdd deadlocks (model self)
    cpdef set scc (model self)
    cpdef sdd scc_union (model self)
    cpdef dict transitions (model self)
