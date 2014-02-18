#ifndef _slb_export_h_
#define _slb_export_h_

#ifndef _FEATURES_H
# include <features.h>
#endif
#include <mint/basepage.h>

typedef long (*SLB_FNC)(BASEPAGE *bp, long fn, short nargs, ...);

#define SLB_EXPORTLIST_START __attribute__((used,section(".slb_fnc_tab"))) static SLB_FNC _slb_export_list[] = {
#define SLB_EXPORTLIST_END };
#define SLB_EMPTY_SLOT ((SLB_FNC)0)

__BEGIN_DECLS

extern long slb_init();
extern void slb_exit();
extern long slb_open(BASEPAGE *bp);
extern long slb_close(BASEPAGE *bp);

__END_DECLS

#endif /* _slb_export_h_ */
