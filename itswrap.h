#define getInitialState_ptr(i) new SDD(i->getInitialState())
#define computeReachable_ptr(i,g) new SDD(i->computeReachable(g))
#define getNextRel(i) new Shom(i.getNextRel())
#define getPredRel(i) new Shom(i.getPredRel())
