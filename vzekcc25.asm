	IDNT	VZEKCC25

	MACHINE	68000
	FPU	0
	FAR
	OPT	P+ 	; position independent code
	OPT	D- 	; debug symbols off
	OPT	O+ 	; all optimizations off
	OPT	OW+	; show optimizations on

	INCLUDE	hardware/custom.i
	INCLUDE	hardware/dmabits.i
	INCLUDE	hardware/intbits.i
	INCLUDE	hardware/cia.i
	INCLUDE	hardware/blit.i
	INCLUDE	graphics/display.i

DISPLAYPAL	EQU	$0020	; hardware/custom.h
DMAF_SET	EQU	DMAF_SETCLR
DMAF_CLR	EQU	0
INTF_SET	EQU	INTF_SETCLR
INTF_CLR	EQU	0

;-----------------------------------------------------------------------------

TEST_NOCBLT	EQU	0	; disable punched code blit/scroll
TEST_PCODEL	EQU	8	; mark punched tape line 0 (colorX)
TEST_CBLIT1	EQU	1	; mark pos after bpl1 blit (green)
TEST_CJUMP2	EQU	1	; mark pos after CPU cjmp2 (pink)

;-----------------------------------------------------------------------------

DIWSTRT_V 	EQU	(44)              	; default vert DIWSTRT
DIWSTRT_H 	EQU	($38*2+17)        	; default horz DIWSTRT
DIWSTOP_V 	EQU	(DIWSTRT_V+256)   	; default vert DIWSTOP
DIWSTOP_H 	EQU	(DIWSTRT_H+320)   	; default horz DIWSTOP
LOGOHEIGHT	EQU	(480)             	; lines, vert centered
LOGOROWLEN	EQU	(480/16)          	; words, horz centered
SCR1ROWLEN	EQU	(3+2+LOGOROWLEN+2)	; words, overlaps next
SCR1BPLMOD	EQU	(2*SCR1ROWLEN-6)  	; bytes, interlaced BPL
SCR1HEIGHT	EQU	(512)             	; interlaced full HiRes
SCR2ROWLEN	EQU	(320/16)          	; words, standard LoRes
SCR2BPLMOD	EQU	(0)               	; bytes, not interlaced
SCR2HEIGHT	EQU	(405)             	; image without borders

;-----------------------------------------------------------------------------
;
;                              RAM memory layout
;

RAM_SIZE	EQU	256*1024

	OFFSET	0
ZeroLocation	so.l	1-0+0   	; VEC_RESETSP
AbsExecBase 	so.l	1-1+1   	; VEC_RESETPC
VecBusError 	so.l	1-2+24  	; VEC_BUSERR-VEC_SPUR
VecIntLevel1	so.l	1-25+25 	; VEC_INT1 (TBE, DSKBLK, SOFTINT)
VecIntLevel2	so.l	1-26+26 	; VEC_INT2 (PORTS)
VecIntLevel3	so.l	1-27+27 	; VEC_INT3 (COPER, VERTB, BLIT)
VecIntLevel4	so.l	1-28+28 	; VEC_INT4 (AUD2, AUD0, AUD3, AUD1)
VecIntLevel5	so.l	1-29+29 	; VEC_INT5 (RBF, DSKSYNC)
VecIntLevel6	so.l	1-30+30 	; VEC_INT6 (EXTER, INTEN)
VecIntLevel7	so.l	1-31+63 	; VEC_INT7-VEC_RESV63
RamStackBuff	so.l	1-64+255	; VEC_USER[192]
RamCopOffset	so.l	(RomImages-RomCopOffset)/4
Scr1Bpl1DatU	so.w	SCR1ROWLEN
Scr1Bpl1DatL	so.w	SCR1ROWLEN*(SCR1HEIGHT-1)
Scr1Bpl1EndL	so.w	3
Scr1Bpl2DatU	so.w	SCR1ROWLEN
Scr1Bpl2DatL	so.w	SCR1ROWLEN*(SCR1HEIGHT-1)
Scr1Bpl2EndL	so.w	3
Scr1Bpl3DatU	so.w	SCR1ROWLEN
Scr1Bpl3DatL	so.w	SCR1ROWLEN*(SCR1HEIGHT-1)
Scr1Bpl3EndL	so.w	3
Scr1Bpl4DatU	so.w	SCR1ROWLEN
Scr1Bpl4DatL	so.w	SCR1ROWLEN*(SCR1HEIGHT-1)
Scr1Bpl4EndL	so.w	3
Scr2Bpl1Data	so.w	SCR2ROWLEN*SCR2HEIGHT
Scr2Bpl2Data	so.w	SCR2ROWLEN*SCR2HEIGHT
Scr2Bpl3Data	so.w	SCR2ROWLEN*SCR2HEIGHT
Scr2Bpl4Data	so.w	SCR2ROWLEN*SCR2HEIGHT
Scr2Bpl5Data	so.w	SCR2ROWLEN*SCR2HEIGHT
Scr2Bpl6Data	so.w	SCR2ROWLEN*SCR2HEIGHT

;-----------------------------------------------------------------------------
;
;                      ROM header / Overlay vector table
;

ROM_SIZE	EQU	256*1024
ROM_256K	EQU	($1111<<16)!$4EF9	; 256K ROM ID, JMP (ABS).L
ROM_FILL	EQU	~0               	; EPROM/Flash optimization

	SECTION	VZEKCC25,CODE
	ORG	$01000000-ROM_SIZE

RomBase:
		dc.l   	ROM_256K          	; VEC_RESETSP
		dc.l   	ColdStart         	; VEC_RESETPC
		dc.l   	$0000FFFF         	; VEC_BUSERR (manf diag tag)
		dc.w   	0,3               	; VEC_ADDRERR (Kick ver,rev)
		dc.w	0,0               	; VEC_ILLEGAL (Exec ver,rev)
		dc.l   	$4BBBB701         	; VEC_ZERODIV (Kick serial)
		dcb.l  	1-6+15,RomExcept  	; VEC_CHK-VEC_UNINT
0$:		dc.b   	'vzekcc25',0,0    	; VEC_RESV16-VEC_SPUR
1$:		dc.w   	$4AFC             	; (RT_MATCHWORD=RTC_MATCHWORD)
		dc.l   	1$                	; (RT_MATCHTAG)
		dc.l   	RomTagEnd         	; (RT_ENDSKIP)
		dc.b   	$00               	; (RT_FLAGS=RTW_NEVER)
		dc.b   	0                 	; (RT_VERSION)
		dc.b   	0                 	; (RT_TYPE=NT_UNKNOWN)
		dc.b   	0                 	; (RT_PRI)
		dc.l   	0$                	; (RT_NAME)
		dc.l   	RomTagStr         	; (RT_IDSTRING)
		dc.l   	RomExcept         	; (RT_INIT)
		dcb.l  	1-25+51,RomExcept 	; VEC_INT1-VEC_FPUNDER
ColdReset:
		reset  	                  	; VEC_FPOE.w
ColdStart:
		bra.b  	0$                	; VEC_FPOE.w
		dcb.l  	1-53+62,RomExcept 	; VEC_FPOVER-VEC_RESV62
0$:		bra.w  	RomEntry          	; VEC_RESV63,VEC_USER[192]
RomExcept:
		lea    	(0$,pc),sp        	; reset and restart on
		rte    	                  	; unhandled exceptions
0$:		dc.w   	%0010011100000000 	; (exception ($00,sp))
		dc.l   	ColdReset         	; (exception ($02,sp))
		dc.w   	(%0000<<12)!(31*4)	; (exception ($06,sp))
		dcb.b  	(*-RomBase)&%0010,0
		dcb.b  	(*-RomBase)&%0100,0
		dcb.b  	(*-RomBase)&%1000,0
RomTagStr:
		dc.b   	'vzekcc25 0.3 (21.07.2025) PAL',13,10,0,0,'$VER: '
		dc.b   	'vzekcc25 0.3 (21.07.2025) PAL',10
		dc.b   	'Licensed under'
		dc.b   	' CC-BY-NC-SA-3.0-DE AND'
		dc.b   	' CC-BY-NC-SA-3.0 AND'
		dc.b   	' CC-BY-NC-SA-4.0 AND'
		dc.b   	' 0BSD',10
		dc.b   	'You have to comply to all licenses to use this work.'
		dc.b   	' This work includes:',10
		dc.b   	'[1] "CC2025 Amiga Kickstart invitation demo - VzEkC Logo",'
		dc.b   	' licensed under CC BY-NC-SA 4.0 by Nico Bendlin <nico@nicode.net>,'
		dc.b   	' adapted from "Logo des Vereins" <https://www.classic-computing.de/der-verein/banner/>'
		dc.b   	' by Verein zum Erhalt klassischer Computer e.V. <info@classic-computing.org>,'
		dc.b   	' used under CC BY-NC-SA 3.0 DE',10
		dc.b   	'[2] "CC2025 Amiga Kickstart invitation demo - CC25 Poster",'
		dc.b   	' licensed under CC BY-NC-SA 4.0 by Nico Bendlin <nico@nicode.net>,'
		dc.b   	' adapted from "CC25 Poster - Kacheln" <https://forum.classic-computing.de/forum/>'
		dc.b   	' by Konstantin Weiss <k@konstantinweiss.com>,'
		dc.b   	' used under CC BY-NC-SA 3.0',10
		dc.b   	'[3] everything else is'
		dc.b   	' licensed under Zero-Clause BSD by Nico Bendlin <nico@nicode.net>',10,0
		dcb.b  	(*-RomBase)&%0001,0
		dcb.b  	(*-RomBase)&%0010,0
		dcb.b  	(*-RomBase)&%0100,0
		dcb.b  	(*-RomBase)&%1000,0

;-----------------------------------------------------------------------------
;
;                                ROM code/data
;

RomEntry:
		move.w 	#$2700,sr     	; supervisor mode, IPL NMI
custom	EQUR	a6
		lea    	($DFF000).L,custom
		move.w 	#(INTF_CLR!((~INTF_SET)&$FFFF)),(intena,custom)
		move.w 	#(INTF_CLR!((~INTF_SET)&$FFFF)),(intreq,custom)
		move.w 	#(DMAF_CLR!DMAF_ALL),(dmacon,custom)
d0zero	EQUR	d0
d1true	EQUR	d1
		moveq  	#0,d0zero
		moveq  	#-1,d1true
InitScreen:
		move.w 	#DISPLAYPAL,(beamcon0,custom)
		move.l 	#(((MODE_640!COLORON!INTERLACE)<<16)!(0)),(bplcon0,custom)	; BPLCON0/BPLCON1
		move.w 	#%0100100,(bplcon2,custom)	; SP01/SP23/SP45/SP67/PF1
		lea    	(color,custom),a0
		move.w 	#$210,(a0)
		move.w 	d0zero,(bpldat,custom)
		lea    	(16*2,a0),a0
		move.l 	#(($9BC<<16)!($9AB)),(a0)+	; COLOR16/COLOR17
		move.l 	#(($999<<16)!($8CE)),(a0)+	; COLOR18/COLOR19
		move.l 	#(($899<<16)!($888)),(a0)+	; COLOR20/COLOR21
		move.l 	#(($882<<16)!($6AC)),(a0)+	; COLOR22/COLOR23
		move.l 	#(($666<<16)!($665)),(a0)+	; COLOR24/COLOR25
		move.l 	#(($662<<16)!($654)),(a0)+	; COLOR26/COLOR27
		move.l 	#(($59B<<16)!($542)),(a0)+	; COLOR28/COLOR29
		move.l 	#(($48A<<16)!($444)),(a0) 	; COLOR30/COLOR31
InitVector:
ciaa  	EQUR	a5
		lea    	($BFE001).L,ciaa
		move.b 	#CIAF_LED!CIAF_OVERLAY,(ciaddra,ciaa)
		bclr.b 	#CIAB_OVERLAY,(ciaa)	; (ciapra,ciaa)
		movea.l	d0zero,a0
		move.l 	d0zero,(a0)+	; ZeroLocation
		move.l 	d0zero,(a0)+	; AbsExecBase
		lea    	(RomExcept,pc),a1
		move.w 	#((RamCopOffset-VecBusError)/4)-1,d2
0$:		move.l 	a1,(a0)+
		dbf    	d2,0$
		move.l 	a0,sp
		lea    	(IntLevel3,pc),a1
		move.l 	a1,(VecIntLevel3).w
CopyCopper:
		lea    	(RomCopOffset,pc),a1
		move.w 	#((RomImages-RomCopOffset)/4)-1,d2
0$:		move.l 	(a1)+,(a0)+
		dbf    	d2,0$
MakeImage1:
		moveq  	#(4)-1,d2
		lea    	(MkImg1Fill,pc),a2
MkImg1Bpls:	lea    	(-((MkImg1Fill-CcittBpls)/4),a2),a2
		movea.l	a0,a3
		move.w 	#(SCR1HEIGHT)-1,d3
MkImg1Line:	moveq  	#(6-((SCR1HEIGHT-1)%7)),d4
		add.w 	d3,d4
		divu   	#7,d4
		moveq   #0,d5
		move.b 	(CcittText,pc,d4.w),d5
		swap   	d4
		lsl.w  	#1,d4
		move.w 	d4,d6
		lsl.w  	#1,d4
		add.w  	d6,d4
		move.l 	(0,a2,d4.w),d6
		and.l  	(CcittMask+0,pc,d5.w),d6
		move.w 	(4,a2,d4.w),d7
		and.w  	(CcittMask+4,pc,d5.w),d7
		move.l 	d6,(a0)+
		move.w 	d7,(a0)+
		move.l 	d1true,(a0)+
		moveq  	#(LOGOROWLEN/2)-1,d4
MkImg1Logo:	cmp.w  	#(SCR1HEIGHT-((SCR1HEIGHT-LOGOHEIGHT)/2)),d3
		bhs.w  	MkImg1Fill
		cmp.w  	#((SCR1HEIGHT-LOGOHEIGHT)/2),d3
		blo.w  	MkImg1Fill
		move.l 	(a1)+,(a0)+
		bra.w  	MkImg1Next
		; punched tape (CCITT-2 codes)
CcittText:	dc.b   	CcittMask-CcittMask
		dc.b   	Ccitt_LF-CcittMask
		dc.b   	Ccitt_E-CcittMask
		dc.b   	Ccitt_D-CcittMask
		dc.b   	Ccitt_LTR-CcittMask
		dc.b   	Ccitt_M-CcittMask
		dc.b   	Ccitt_FIG-CcittMask
		dc.b   	Ccitt_G-CcittMask
		dc.b   	Ccitt_N-CcittMask
		dc.b   	Ccitt_I-CcittMask
		dc.b   	Ccitt_T-CcittMask
		dc.b   	Ccitt_U-CcittMask
		dc.b   	Ccitt_P-CcittMask
		dc.b   	Ccitt_M-CcittMask
		dc.b   	Ccitt_O-CcittMask
		dc.b   	Ccitt_C-CcittMask
		dc.b   	Ccitt_LTR-CcittMask
		dc.b   	Ccitt_A-CcittMask
		dc.b   	Ccitt_FIG-CcittMask
		dc.b   	Ccitt_C-CcittMask
		dc.b   	Ccitt_I-CcittMask
		dc.b   	Ccitt_S-CcittMask
		dc.b   	Ccitt_S-CcittMask
		dc.b   	Ccitt_A-CcittMask
		dc.b   	Ccitt_L-CcittMask
		dc.b   	Ccitt_C-CcittMask
		dc.b   	Ccitt_LF-CcittMask
		dc.b   	Ccitt_LTR-CcittMask
		dc.b   	Ccitt_M-CcittMask
		dc.b   	Ccitt_FIG-CcittMask
		dc.b   	Ccitt_V-CcittMask
		dc.b   	Ccitt_LTR-CcittMask
		dc.b   	Ccitt_M-CcittMask
		dc.b   	Ccitt_FIG-CcittMask
		dc.b   	Ccitt_E-CcittMask
		dc.b   	Ccitt_SP-CcittMask
		dc.b   	Ccitt_R-CcittMask
		dc.b   	Ccitt_E-CcittMask
		dc.b   	Ccitt_T-CcittMask
		dc.b   	Ccitt_U-CcittMask
		dc.b   	Ccitt_P-CcittMask
		dc.b   	Ccitt_M-CcittMask
		dc.b   	Ccitt_O-CcittMask
		dc.b   	Ccitt_C-CcittMask
		dc.b   	Ccitt_SP-CcittMask
		dc.b   	Ccitt_R-CcittMask
		dc.b   	Ccitt_E-CcittMask
		dc.b   	Ccitt_H-CcittMask
		dc.b   	Ccitt_C-CcittMask
		dc.b   	Ccitt_S-CcittMask
		dc.b   	Ccitt_I-CcittMask
		dc.b   	Ccitt_S-CcittMask
		dc.b   	Ccitt_S-CcittMask
		dc.b   	Ccitt_A-CcittMask
		dc.b   	Ccitt_L-CcittMask
		dc.b   	Ccitt_K-CcittMask
		dc.b   	Ccitt_SP-CcittMask
		dc.b   	Ccitt_T-CcittMask
		dc.b   	Ccitt_L-CcittMask
		dc.b   	Ccitt_A-CcittMask
		dc.b   	Ccitt_H-CcittMask
		dc.b   	Ccitt_R-CcittMask
		dc.b   	Ccitt_E-CcittMask
		dc.b   	Ccitt_SP-CcittMask
		dc.b   	Ccitt_M-CcittMask
		dc.b   	Ccitt_U-CcittMask
		dc.b   	Ccitt_Z-CcittMask
		dc.b   	Ccitt_SP-CcittMask
		dc.b   	Ccitt_N-CcittMask
		dc.b   	Ccitt_I-CcittMask
		dc.b   	Ccitt_E-CcittMask
		dc.b   	Ccitt_R-CcittMask
		dc.b   	Ccitt_E-CcittMask
		dc.b   	Ccitt_V-CcittMask
CcittMask:	dc.w   	%1110000000000000,%0000000000000000,%0000000000000111
Ccitt_A:	dc.w   	%1110000000000000,%0000000011111111,%1111111111111111
Ccitt_C:	dc.w   	%1110000000111111,%1111111111111111,%1111110000000111
Ccitt_D:	dc.w   	%1110000000111111,%1000000011111110,%0000001111111111
Ccitt_E:	dc.w   	%1110000000000000,%0000000011111110,%0000001111111111
Ccitt_G:	dc.w   	%1111111111111111,%1000000011111111,%1111110000000111
Ccitt_H:	dc.w   	%1111111111000000,%0111111111111110,%0000000000000111
Ccitt_I:	dc.w   	%1110000000000000,%0111111111111111,%1111110000000111
Ccitt_K:	dc.w   	%1110000000111111,%1111111111111111,%1111111111111111
Ccitt_L:	dc.w   	%1111111111000000,%0000000011111111,%1111110000000111
Ccitt_M:	dc.w   	%1111111111111111,%1111111111111110,%0000000000000111
Ccitt_N:	dc.w   	%1110000000111111,%1111111111111110,%0000000000000111
Ccitt_O:	dc.w   	%1111111111111111,%1000000011111110,%0000000000000111
Ccitt_P:	dc.w   	%1111111111000000,%0111111111111111,%1111110000000111
Ccitt_R:	dc.w   	%1110000000111111,%1000000011111111,%1111110000000111
Ccitt_S:	dc.w   	%1110000000000000,%0111111111111110,%0000001111111111
Ccitt_T:	dc.w   	%1111111111000000,%0000000011111110,%0000000000000111
Ccitt_U:	dc.w   	%1110000000000000,%0111111111111111,%1111111111111111
Ccitt_V:	dc.w   	%1111111111111111,%1111111111111111,%1111110000000111
Ccitt_Z:	dc.w   	%1111111111000000,%0000000011111110,%0000001111111111
Ccitt_LF:	dc.w   	%1110000000000000,%0000000011111111,%1111110000000111
Ccitt_SP:	dc.w   	%1110000000000000,%0111111111111110,%0000000000000111
Ccitt_FIG:	dc.w   	%1111111111111111,%1000000011111111,%1111111111111111
Ccitt_LTR:	dc.w   	%1111111111111111,%1111111111111111,%1111111111111111
CcittBpls:	; bitplanes and lines reversed
		dc.w   	%0000001000001100,%0000100000000000,%0010000001000000
		dc.w   	%0000111110011111,%0011111000010000,%1111100111110000
		dc.w   	%0000111110011111,%0011111000111000,%1111100111110000
		dc.w   	%0000111110011111,%0011111000111000,%1111100111110000
		dc.w   	%0000111110011111,%0011111000010000,%1111100111110000
		dc.w   	%0000011000000100,%0001100000000000,%0010000011000000
		dc.w   	%0000000000000000,%0000000000000000,%0000000000000000
		dc.w   	%0000010100000110,%0001010000000000,%0101000010100000
		dc.w   	%0000111100011110,%0011110000111000,%1111000111100000
		dc.w   	%0000111110011111,%0011111001111000,%1111100111110000
		dc.w   	%0000111110011111,%0011111001111000,%1111100111110000
		dc.w   	%0000111100011111,%0011110000111000,%1111000111100000
		dc.w   	%0000001100001010,%0000110000000000,%0111000001100000
		dc.w   	%0000000000000000,%0000000000000000,%0000000000000000
		dc.w   	%0000011000001010,%0001100000000000,%0110000011000000
		dc.w   	%0000011110001111,%0001111000100000,%0111100011110000
		dc.w   	%0001111110111111,%0111111000111101,%1111101111110000
		dc.w   	%0001111110111111,%0111111000111101,%1111101111110000
		dc.w   	%0000011110001111,%0001111000101000,%0111100011110000
		dc.w   	%0000010100001100,%0001010000000000,%0101000010100000
		dc.w   	%0000000000000000,%0000000000000000,%0000000000000000
		dc.w   	%0000001100000000,%0000110000000000,%0111000001100000
		dc.w   	%0000011100011110,%0001110000001000,%1111000011100000
		dc.w   	%0000111111011111,%1011111100111001,%1111111111111000
		dc.w   	%0000111111011111,%1011111100111001,%1111111111111000
		dc.w   	%0000111110011110,%0011111000110000,%1111000111110000
		dc.w   	%0000000100001110,%0000010000000000,%0100000000100000
		dc.w   	%0000000000000000,%0000000000000000,%0000000000000000
MkImg1Fill:	move.l 	d1true,(a0)+
MkImg1Next:	dbf    	d4,MkImg1Logo
		move.l 	d1true,(a0)+
		dbf    	d3,MkImg1Line
		move.l 	(a3)+,(a0)+
		move.w 	(a3),(a0)+
	IFGE	TEST_PCODEL-1
		; BTST.B Dn,#<data> might be the most unknown,
		; coolest, and least used user mode opcode :-)
		; (tests if the bit Dn is present in #<data>).
		moveq  	#0,d7
		btst.b 	d2,#(((TEST_PCODEL&1)<<3)!((TEST_PCODEL&2)<<1)!((TEST_PCODEL&4)>>1)!((TEST_PCODEL&8)>>3))	; reversed (due to DBcc)
		beq.b  	0$
		not.l  	d7
0$:		move.w 	d7,-(a3)  	; first line/frame (TEST_NOCBLT)
		move.w 	d7,(-6,a0)	; Scr1BplXEndL (scrolled in bpl)
		move.w 	d7,(-2,a0)
	ENDC
		dbf    	d2,MkImg1Bpls
CopyImage2:
		moveq  	#(6)-1,d2
0$:		move.w 	#(SCR2HEIGHT)-1,d3
1$:		moveq  	#(SCR2ROWLEN/2)-1,d4
2$:		move.l 	(a1)+,(a0)+
		dbf    	d4,2$
		dbf    	d3,1$
		dbf    	d2,0$

;-----------------------------------------------------------------------------

CIR1_DA 	EQU	$01FE	; MOVE CIR2,(DA,custom)
CIR1_WAIT	EQU	$0001	; WAIT/SKIP
CIR1_VP  	EQU	$FF00	; WAIT/SKIP
CIR1_HP  	EQU	$00FE	; WAIT/SKIP
CIR2_BFD 	EQU	$8000	; WAIT/SKIP
CIR2_VE  	EQU	$7F00	; WAIT/SKIP (VP:7 is always enabled)
CIR2_HE  	EQU	$00FE	; WAIT/SKIP
CIR2_SKIP	EQU	$0001	; SKIP

CINS_NOP 	EQU	(((CIR1_DA)<<16)!(CIR2_BFD))	; faster than WAIT
CINS_STOP	EQU	(((CIR1_WAIT!CIR1_VP!CIR1_HP)<<16)!(CIR2_BFD!CIR2_VE!CIR2_HE))
CINS_W256	EQU	(((CIR1_WAIT!CIR1_VP!$DE)<<16)!(CIR2_BFD!CIR2_VE!CIR2_HE))
CINS_WBLT	EQU	(((CIR1_WAIT)<<16)!(0))	; any, without CIR2_BFD

BFD

CopNumber	EQUR	d7
CopFrames	EQUR	d6

InitBltCop:
		moveq  	#0,CopNumber
		moveq  	#0,CopFrames	; forever (P1988DT09H51M31.84S)
		move.l 	#(((BC0F_SRCA!BC0F_DEST!ABC!ABNC!ANBC!ANBNC)<<16)!(0)),(bltcon0,custom)	; BLTCON0/BLTCON01
		move.l 	#(((SCR1BPLMOD)<<16)!(SCR1BPLMOD)),(bltamod,custom)
		move.l 	d1true,(bltafwm,custom)	; BLTAFWM/BLTALWM
		move.w 	#$0002,(copcon,custom) 	; CDANG (Copper blitter access)
		move.l 	#((RomCop0_2-RomCopOffset)+RamCopOffset),(cop2lc,custom)	; COP2LCH/COP2LCL
		move.l 	#((RomCop0_1-RomCopOffset)+RamCopOffset),(cop1lc,custom)	; COP1LCH/COP1LCL
		move.w 	#(INTF_SET!INTF_INTEN!INTF_COPER),(intena,custom)
EnableDMAs:
		move.w 	#(DMAF_SET!DMAF_BLITHOG!DMAF_MASTER!DMAF_RASTER!DMAF_COPPER!DMAF_BLITTER),(dmacon,custom)
WaitForInt:
		; CPU off - wait for interrupt (IntLevel3)
		stop   	#$2200	; supervisor mode, IPL 3-1
		bra.b  	WaitForInt

;-----------------------------------------------------------------------------

setcop1	MACRO	; rom
		move.w 	#(((\1)-RomCopOffset)+RamCopOffset),(cop1lc+2,custom)	; COP1LCL
	ENDM
setcop2	MACRO	; rom
		move.w 	#(((\1)-RomCopOffset)+RamCopOffset),(cop2lc+2,custom)	; COP2LCL
	ENDM

IntLevel3:
		btst.b 	#INTB_COPER,(intreqr+1,custom)
		beq.b  	IntReturn
		subq.l 	#1,CopFrames
		bne.b  	CopUpdate
CopSwitch:
		move.w 	CopNumber,d2
		addq.w 	#1*2,CopNumber
		lsl.w  	#1,d2
		move.l 	(CopStates,pc,d2.w),d2
		move.w 	d2,CopFrames
		swap   	d2
		jmp    	(CopStates,pc,d2.w)
CopStates:
		dc.w   	CopState1-CopStates,SCR1HEIGHT/4
		dc.w   	CopState2-CopStates,25*1
		dc.w   	CopState0-CopStates,SCR1HEIGHT/4
CopState1:	; show Logo (scroll punched tape)
		setcop2	RomCop1_2
		setcop1	RomCop1_1
		bra.b  	CopReturn
CopState2:	; from Logo to Poster
		setcop2	RomCop2_2U
		setcop1	RomCop2_1
		; avoid HW bug (CPU copper jump during blit)
		btst.b 	#(DMAB_BLTDONE-8),(dmaconr+0,custom)	; twice (ICS)
0$:		btst.b 	#(DMAB_BLTDONE-8),(dmaconr+0,custom)
		bne.b  	0$
		move.w 	d0zero,(copjmp2,custom)
		bra.b  	CopReturn
CopState0:
		setcop2	RomCop1_2
		setcop1	RomCop1_1
		moveq  	#1*2,CopNumber
		;TODO: revert Copper code updates
CopReturn:
		move.w 	#(INTF_CLR!INTF_COPER),(intreq,custom)
IntReturn:
		rte
CopWaitLF:
		btst.b 	#(15-8),(vposr+0,custom)	; LOF
		bne.b  	CopReturn
		moveq  	#0,CopFrames
		bra.b  	CopSwitch
CopUpdate:
		move.w 	(0$,pc,CopNumber.w),d2
		jmp    	(0$,pc,d2.w)
0$:		dc.w   	CopWaitLF-0$	; 0
		dc.w   	CopReturn-0$	; 1
		dc.w   	CopReturn-0$	; 2
	IFNE	(*-0$)-((CopState1-CopStates)/2)
	FAIL	"FIXME: Copper state and update table size differ."
	ENDC

;-----------------------------------------------------------------------------

		dcb.b  	(*-RomBase)&%0010,0

RomCopOffset:

cstrt	MACRO
CWAITFF	SET	0
	ENDM
cmove	MACRO	; rga,val
		dc.w 	CIR1_DA&(\1),(\2)
	ENDM
clong	MACRO	; rga,val
		cmove	(\1)+0,(\2)>>16
		cmove	(\1)+2,(\2)&$FFFF
	ENDM
cwait	MACRO	; vpos,hpos
	IFGE	(\1)-256
	IFEQ	CWAITFF-0
CWAITFF	SET	1
		dc.l 	CINS_W256
	ENDC
	ELSE
	IFEQ	CWAITFF-1
	FAIL	"FIXME: Copper backwards wait."
	ENDC
	ENDC
		dc.w 	(CIR1_WAIT!(CIR1_VP&(((\1)<<8)))!(CIR1_HP&(\2))),(CIR2_BFD!CIR2_VE!CIR2_HE)
	ENDM
cblit	MACRO	; src,dst,cnt
	IFEQ	TEST_NOCBLT
		dc.l 	CINS_WBLT,CINS_WBLT	; twice (ICS)
		clong	bltapt,(\1)
		clong	bltdpt,(\2)
		cmove	bltsize,((\3)<<HSIZEBITS)!3
	ENDC
	ENDM
csetb	MACRO	; num,bplpt
		clong	bplpt+(((\1)-1)*4),(\2)
	ENDM
csetc	MACRO	; index,color
		cmove	color+((\1)*2),(\2)
	ENDM
cfade	MACRO	; vpos,color
		cwait	(\1),$0C
		csetc	0,(\2)
	ENDM
cset2	MACRO	; rom
		cmove	cop2lc+2,((\1)-RomCopOffset)+RamCopOffset
	ENDM
cjmp2	MACRO
		cmove	copjmp2,0
	ENDM
cint3	MACRO
		cmove	intreq,INTF_SET!INTF_COPER
	ENDM
cstop	MACRO
		dc.l   	CINS_STOP
	ENDM

RomCop0_1:
		cstrt
		cwait	256,0
		cint3
RomCop0_2:
		cstop

RomCop1_1:
RomCop2_1:	;FIXME: dev dummy
		cstrt
	;	csetc	0,$210
		csetc	1,$322
		csetc	2,$432
		csetc	3,$433
		csetc	4,$543
		csetc	5,$654
		csetc	6,$765
		csetc	7,$876
		csetc	8,$A63
		csetc	9,$B74
		csetc	10,$A87
		csetc	11,$B98
		csetc	12,$CA8
		csetc	13,$DB9
		csetc	14,$ECA
		csetc	15,$FDB
		cmove	bplcon0,MODE_640!(4<<PLNCNTSHFT)!COLORON!INTERLACE
		cmove	diwstrt,(DIWSTRT_V<<8)!DIWSTRT_H
		cmove	diwstop,((DIWSTOP_V&$FF)<<8)!(DIWSTOP_H&$FF)
		cmove	ddfstrt,(DIWSTRT_H-9)/2
		cmove	ddfstop,(DIWSTOP_H-9-16)/2
		cmove	bpl1mod,SCR1BPLMOD
		cmove	bpl2mod,SCR1BPLMOD
		cjmp2
RomCop1_2:
		cstrt
		cset2	RomCop1_2L
		csetb	1,Scr1Bpl1DatU
		csetb	2,Scr1Bpl2DatU
		csetb	3,Scr1Bpl3DatU
		csetb	4,Scr1Bpl4DatU
		cfade	DIWSTRT_V-6,$EDC
		cfade	DIWSTRT_V-5,$CBA
		cfade	DIWSTRT_V-4,$A98
		cfade	DIWSTRT_V-3,$876
		cfade	DIWSTRT_V-2,$654
		cfade	DIWSTRT_V-1,$432
		cfade	DIWSTRT_V-0,$210
		cfade	DIWSTOP_V+0,$321
		cfade	DIWSTOP_V+1,$543
		cfade	DIWSTOP_V+2,$765
		cfade	DIWSTOP_V+3,$987
		cfade	DIWSTOP_V+4,$BA9
		cfade	DIWSTOP_V+5,$DCB
		cfade	DIWSTOP_V+6,$FED
		cfade	DIWSTOP_V+7,$FFF
		cstop
RomCop1_2U:
		cstrt
		cset2	RomCop1_2L
		csetb	1,Scr1Bpl1DatU
		csetb	2,Scr1Bpl2DatU
		csetb	3,Scr1Bpl3DatU
		csetb	4,Scr1Bpl4DatU
		cblit	Scr1Bpl3DatL,Scr1Bpl3DatU,SCR1HEIGHT
		cblit	Scr1Bpl4DatL,Scr1Bpl4DatU,SCR1HEIGHT
		cblit	Scr1Bpl1DatU,Scr1Bpl1EndL,1
		cblit	Scr1Bpl2DatU,Scr1Bpl2EndL,1
		cblit	Scr1Bpl3DatU,Scr1Bpl3EndL,1
		cblit	Scr1Bpl4DatU,Scr1Bpl4EndL,1
		cint3
	IFEQ	TEST_CJUMP2-1
		csetc	0,$F0F
	ENDC
		cfade	DIWSTRT_V-6,$EDC
		cfade	DIWSTRT_V-5,$CBA
		cfade	DIWSTRT_V-4,$A98
		cfade	DIWSTRT_V-3,$876
		cfade	DIWSTRT_V-2,$654
		cfade	DIWSTRT_V-1,$432
		cfade	DIWSTRT_V-0,$210
		cfade	DIWSTOP_V+0,$321
		cfade	DIWSTOP_V+1,$543
		cfade	DIWSTOP_V+2,$765
		cfade	DIWSTOP_V+3,$987
		cfade	DIWSTOP_V+4,$BA9
		cfade	DIWSTOP_V+5,$DCB
		cfade	DIWSTOP_V+6,$FED
		cfade	DIWSTOP_V+7,$FFF
		cstop
RomCop1_2L:
		cstrt
		cset2	RomCop1_2U
	;	cint3	; in RomCop1_2U due to blit over EOF
		csetb	1,Scr1Bpl1DatL
		csetb	2,Scr1Bpl2DatL
		csetb	3,Scr1Bpl3DatL
		csetb	4,Scr1Bpl4DatL
		cfade	DIWSTRT_V-7,$FED
		cfade	DIWSTRT_V-6,$DCB
		cfade	DIWSTRT_V-5,$BA9
		cfade	DIWSTRT_V-4,$987
		cfade	DIWSTRT_V-3,$765
		cfade	DIWSTRT_V-2,$543
		cfade	DIWSTRT_V-1,$321
		cfade	DIWSTRT_V-0,$210
		cwait	DIWSTOP_V-49,$1C	;TEST: blit ends in DIWSTOP line
		cblit	Scr1Bpl1DatL,Scr1Bpl1DatU,SCR1HEIGHT
	IFEQ	TEST_CBLIT1-1-TEST_NOCBLT
		dc.l 	CINS_WBLT
		csetc	0,$0F0
CWAITFF	SET	1
	ENDC
		cblit	Scr1Bpl2DatL,Scr1Bpl2DatU,SCR1HEIGHT
		cfade	DIWSTOP_V+0,$432
		cfade	DIWSTOP_V+1,$654
		cfade	DIWSTOP_V+2,$876
		cfade	DIWSTOP_V+3,$A98
		cfade	DIWSTOP_V+4,$CBA
		cfade	DIWSTOP_V+5,$EDC
		cfade	DIWSTOP_V+6,$FFF
		cstop

RomCop2_2U:	;FIXME: dev dummy
		cstrt
		cset2	RomCop2_2L
		csetb	1,Scr1Bpl1DatU
		csetb	2,Scr1Bpl2DatU
		csetb	3,Scr1Bpl3DatU
		csetb	4,Scr1Bpl4DatU
		cfade	DIWSTRT_V-6,$EDC
		cfade	DIWSTRT_V-5,$CBA
		cfade	DIWSTRT_V-4,$A98
		cfade	DIWSTRT_V-3,$876
		cfade	DIWSTRT_V-2,$654
		cfade	DIWSTRT_V-1,$432
		cfade	DIWSTRT_V-0,$210
		cfade	DIWSTOP_V+0,$321
		cfade	DIWSTOP_V+1,$543
		cfade	DIWSTOP_V+2,$765
		cfade	DIWSTOP_V+3,$987
		cfade	DIWSTOP_V+4,$BA9
		cfade	DIWSTOP_V+5,$DCB
		cfade	DIWSTOP_V+6,$FED
		cfade	DIWSTOP_V+7,$FFF
		cstop
RomCop2_2L:	;FIXME: dev dummy
		cstrt
		cset2	RomCop2_2U
		cint3
		csetb	1,Scr1Bpl1DatL
		csetb	2,Scr1Bpl2DatL
		csetb	3,Scr1Bpl3DatL
		csetb	4,Scr1Bpl4DatL
		cfade	DIWSTRT_V-7,$FED
		cfade	DIWSTRT_V-6,$DCB
		cfade	DIWSTRT_V-5,$BA9
		cfade	DIWSTRT_V-4,$987
		cfade	DIWSTRT_V-3,$765
		cfade	DIWSTRT_V-2,$543
		cfade	DIWSTRT_V-1,$321
		cfade	DIWSTRT_V-0,$210
		cfade	DIWSTOP_V+0,$432
		cfade	DIWSTOP_V+1,$654
		cfade	DIWSTOP_V+2,$876
		cfade	DIWSTOP_V+3,$A98
		cfade	DIWSTOP_V+4,$CBA
		cfade	DIWSTOP_V+5,$EDC
		cfade	DIWSTOP_V+6,$FFF
		cstop

;-----------------------------------------------------------------------------

RomImages:

	INCLUDE	imagedat.i

;-----------------------------------------------------------------------------

RomTagEnd:

	NOLIST

RAM_USED	EQU	__SO
RAM_FREE	EQU	RAM_SIZE-RAM_USED
ROM_USED	EQU	RomTagEnd-RomBase
ROM_FREE	EQU	ROM_SIZE-ROM_USED-(2*4)-(8*2)	; -footer

	IFGE	RAM_FREE
raminfo	MACRO
	PRINTT	"RAM usage: \<RAM_USED>+\<RAM_FREE>"
	ENDM
	ELSE
raminfo	MACRO
RAM_OVER	EQU	-RAM_FREE
	PRINTT	"RAM usage: \<RAM_USED>-\<RAM_OVER>"
	ENDM
	ENDC
	IFGE	ROM_FREE
rominfo	MACRO
	PRINTT	"ROM usage: \<ROM_USED>+\<ROM_FREE>"
	ENDM
	ELSE
rominfo	MACRO
ROM_OVER	EQU	-ROM_FREE
	PRINTT	"ROM usage: \<ROM_USED>-\<ROM_OVER>"
	ENDM
	ENDC
		raminfo
		rominfo

	IFLT	RAM_FREE
	IFLT	ROM_FREE
	FAIL	"FIXME: RAM and ROM space overflow."
	ELSE
	FAIL	"FIXME: RAM space overflow."
	ENDC
	ELSE
	IFLT	ROM_FREE
	FAIL	"FIXME: ROM space overflow."
	ENDC
	ENDC

;-----------------------------------------------------------------------------
;
;                                 ROM footer
;
		dcb.b  	ROM_FREE,ROM_FILL
		dc.l   	$00000000	; Kickstart ROM checksum
		dc.l   	ROM_SIZE 	; Kickstart ROM size
		dc.b   	0,24	; Spurious Interrupt
		dc.b   	0,25	; Autovector Level 1 (TBE, DSKBLK, SOFTINT)
		dc.b   	0,26	; Autovector Level 2 (PORTS)
		dc.b   	0,27	; Autovector Level 3 (COPER, VERTB, BLIT)
		dc.b   	0,28	; Autovector Level 4 (AUD2, AUD0, AUD3, AUD1)
		dc.b   	0,29	; Autovector Level 5 (RBF, DSKSYNC)
		dc.b   	0,30	; Autovector Level 6 (EXTER, INTEN)
		dc.b   	0,31	; Autovector Level 7 (NMI)

	END
