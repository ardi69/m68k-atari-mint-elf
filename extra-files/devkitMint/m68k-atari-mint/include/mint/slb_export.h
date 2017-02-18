#ifndef _slb_export_h_
#define _slb_export_h_

#ifndef _FEATURES_H
# include <features.h>
#endif
#include <mint/basepage.h>

typedef long (*SLB_FNC)(BASEPAGE *bp, long fn, short nargs, ...);

#define SLB_EXPORT(SLOT) __attribute__((slb_export(SLOT)))

__BEGIN_DECLS

extern long slb_init();
extern void slb_exit();
extern long slb_open(BASEPAGE *bp);
extern long slb_close(BASEPAGE *bp);
extern long slb_version;
extern const char slb_name[];

__END_DECLS

#endif /* _slb_export_h_ */
