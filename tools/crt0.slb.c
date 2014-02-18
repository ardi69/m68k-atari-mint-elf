
__asm__(
".section	.slb_head,\"aw\",@progbits		\n"
"	.long 0x70004afc			/* magic		*/	\n"
"	.long slb_info				/* name		*/	\n"
"	.long 1						/* version	*/	\n"
"	.long 0						/* flags		*/	\n"
"	.long __slb_init			/* init		*/	\n"
"	.long __slb_exit			/* exit		*/	\n"
"	.long _slb_open			/* open		*/	\n"
"	.long _slb_close			/* close		*/	\n"
"	.long 0						/* Option	*/	\n"
"	.long 0						/* Next		*/	\n"
"	.long 0						/* Reserved	*/	\n"
"	.long 0						/* Reserved	*/	\n"
"	.long 0						/* Reserved	*/	\n"
"	.long 0						/* Reserved	*/	\n"
"	.long 0						/* Reserved	*/	\n"
"	.long 0						/* Reserved	*/	\n"
"	.long 0						/* Reserved	*/	\n"
"	.long 0						/* Reserved	*/	\n"
"	.text												\n"
);

__asm__(
"slb_info:											\n"
"	.long _slb_name			/* name		*/	\n"
"	.long _slb_version		/* version	*/	\n"
);


extern long slb_init();
extern void slb_exit();
typedef void (*func_ptr)();
extern func_ptr __CTOR_LIST__[];
extern func_ptr __DTOR_LIST__[];

__attribute((used)) static long _slb_init() {
	__SIZE_TYPE__ nptrs = (__SIZE_TYPE__) __CTOR_LIST__[0];		\
	unsigned i;								\
	if (nptrs == (__SIZE_TYPE__)-1)				        \
		for (nptrs = 0; __CTOR_LIST__[nptrs + 1] != 0; nptrs++);		\
	for (i = nptrs; i >= 1; i--)						\
		__CTOR_LIST__[i] ();						\
	return slb_init();
}
__attribute((used)) static void _slb_exit() {
	slb_exit();
	func_ptr *p, f;
	for (p = __DTOR_LIST__ + 1; (f = *p); p++)
		f ();
}
