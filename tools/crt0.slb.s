
	.section	.slb_head,"aw",@progbits		
	.long 0x70004afc			/* magic		*/	
	.long _slb_name				/* name		*/
	.long 1						/* version	*/	
	.long 0						/* flags		*/	
	.long .slb_init			/* init		*/	
	.long .slb_exit			/* exit		*/	
	.long _slb_open			/* open		*/	
	.long _slb_close			/* close		*/	
	.long 0						/* Option	*/	
	.long 0						/* Next		*/	
	.long 0						/* Reserved	*/	
	.long 0						/* Reserved	*/	
	.long 0						/* Reserved	*/	
	.long 0						/* Reserved	*/	
	.long 0						/* Reserved	*/	
	.long 0						/* Reserved	*/	
	.long 0						/* Reserved	*/	
	.text												

	.long _slb_version		/* version	*/	

	.text
	.even
.slb_init:
	move.l %a2,-(%sp)
	move.l %d2,-(%sp)
	move.l ___CTOR_LIST__,%d2
	moveq #-1,%d0
	cmp.l %d2,%d0
	jeq .L14
.L2:
	tst.l %d2
	jeq .L5
	move.l %d2,%a2
	add.l %d2,%a2
	add.l %a2,%a2
	add.l #___CTOR_LIST__+4,%a2
.L6:
	move.l -(%a2),%a0
	jsr (%a0)
	subq.l #1,%d2
	jne .L6
.L5:
	move.l (%sp)+,%d2
	move.l (%sp)+,%a2
	jra _slb_init
.L14:
	lea ___CTOR_LIST__+4,%a0
	moveq #0,%d2
.L3:
	move.l %d2,%d0
	addq.l #1,%d0
	tst.l (%a0)+
	jeq .L2
	move.l %d0,%d2
	jra .L3
	.even
.slb_exit:
	move.l %a2,-(%sp)
	jsr _slb_exit
	move.l ___DTOR_LIST__+4,%a0
	lea ___DTOR_LIST__+8,%a2
	cmp.l #0,%a0
	jeq .L16
.L22:
	jsr (%a0)
	move.l (%a2)+,%a0
	cmp.l #0,%a0
	jne .L22
.L16:
	move.l (%sp)+,%a2
	rts
