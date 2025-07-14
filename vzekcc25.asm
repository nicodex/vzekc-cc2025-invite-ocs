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

;-----------------------------------------------------------------------------

LOGOHEIGHT	EQU	(480)             	; lines, vertically centered
LOGOROWLEN	EQU	(480/16)          	; words, horizontally centered
SCR1ROWLEN	EQU	(3+2+LOGOROWLEN+2)	; words, overlaps into next +3
SCR1BPLMOD	EQU	(2*SCR1ROWLEN-6)  	; bytes, interlaced BPL
SCR1HEIGHT	EQU	(256*2)           	; interlaced full HiRes
SCR2ROWLEN	EQU	(320/16)          	; words, standard LoRes screen
SCR2BPLMOD	EQU	(0)               	; bytes, not interlaced
SCR2BORDER	EQU	(3)               	; screen top and bottom
SCR2HEIGHT	EQU	(405)             	; image without borders

;-----------------------------------------------------------------------------
;
;                              RAM memory layout
;

RAM_SIZE	EQU	256*1024

	OFFSET	0
ZeroLocation	so.l	1-0+0   	; VEC_RESETSP
AbsExecBase	so.l	1-1+1   	; VEC_RESETPC
VecBusError	so.l	1-2+24  	; VEC_BUSERR-VEC_SPUR
VecIntLevel1	so.l	1-25+25 	; VEC_INT1 (TBE, DSKBLK, SOFTINT)
VecIntLevel2	so.l	1-26+26 	; VEC_INT2 (PORTS)
VecIntLevel3	so.l	1-27+27 	; VEC_INT3 (COPER, VERTB, BLIT)
VecIntLevel4	so.l	1-28+28 	; VEC_INT4 (AUD2, AUD0, AUD3, AUD1)
VecIntLevel5	so.l	1-29+29 	; VEC_INT5 (RBF, DSKSYNC)
VecIntLevel6	so.l	1-30+30 	; VEC_INT6 (EXTER, INTEN)
VecIntLevel7	so.l	1-31+63 	; VEC_INT7-VEC_RESV63
RamStackBuff	so.l	1-64+255	; VEC_USER[192]
RamCoperBase	so.l	(RomImages-RomCopper)/4
Scr1Bpl1Dat0	so.w	SCR1ROWLEN
Scr1Bpl1Dat1	so.w	SCR1ROWLEN*(SCR1HEIGHT-1)
Scr1Bpl1Rot0	so.w	3
Scr1Bpl1Rot1	so.w	3
Scr1Bpl2Dat0	so.w	SCR1ROWLEN
Scr1Bpl2Dat1	so.w	SCR1ROWLEN*(SCR1HEIGHT-1)
Scr1Bpl2Rot0	so.w	3
Scr1Bpl2Rot1	so.w	3
Scr1Bpl3Dat0	so.w	SCR1ROWLEN
Scr1Bpl3Dat1	so.w	SCR1ROWLEN*(SCR1HEIGHT-1)
Scr1Bpl3Rot0	so.w	3
Scr1Bpl3Rot1	so.w	3
Scr1Bpl4Dat0	so.w	SCR1ROWLEN
Scr1Bpl4Dat1	so.w	SCR1ROWLEN*(SCR1HEIGHT-1)
Scr1Bpl4Rot0	so.w	3
Scr1Bpl4Rot1	so.w	3
Scr2Bpl1Dat0	so.w	SCR2ROWLEN*SCR2HEIGHT
Scr2Bpl2Dat0	so.w	SCR2ROWLEN*SCR2HEIGHT
Scr2Bpl3Dat0	so.w	SCR2ROWLEN*SCR2HEIGHT
Scr2Bpl4Dat0	so.w	SCR2ROWLEN*SCR2HEIGHT
Scr2Bpl5Dat0	so.w	SCR2ROWLEN*SCR2HEIGHT
Scr2Bpl6Dat0	so.w	SCR2ROWLEN*SCR2HEIGHT

RAM_USED	so.l	0
RAM_FREE	EQU	RAM_SIZE-RAM_USED
	PRINTT	'RAM free:'
	PRINTV	RAM_FREE

;-----------------------------------------------------------------------------
;
;                      ROM header / Overlay vector table
;

ROM_SIZE	EQU	256*1024
ROM_256K	EQU	($1111<<16)!$4EF9	; 256K ROM ID, JMP (ABS).L
ROM_FILL	EQU	~0               	; EPROM/Flash optimization

	SECTION	vzekcc25,CODE
	ORG	$01000000-ROM_SIZE

RomBase:
		dc.l   	ROM_256K          	; VEC_RESETSP
		dc.l   	ColdStart         	; VEC_RESETPC
		dcb.l  	1-2+11,RomExcept  	; VEC_BUSERR-VEC_LINE11
		dc.l   	$CE48592D         	; VEC_RESV12 (release chksum=0)
		dcb.l  	1-13+15,RomExcept 	; VEC_COPROC-VEC_UNINT
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
		dcb.l  	1-53+58,RomExcept 	; VEC_FPOVER-VEC_MMUACC
0$:		bra.w  	RomEntry          	; VEC_RESV59
		dcb.l  	1-60+61,RomExcept 	; VEC_UNIMPEA-VEC_UNIMPII
RomExcept:
		lea    	(0$,pc),sp        	; VEC_RESV62.w
		rte    	                  	; VEC_RESV62.w-VEC_USER[192]
0$:		dc.w   	%0010011100000000 	; (exception ($00,sp))
		dc.l   	ColdReset         	; (exception ($02,sp))
		dc.w   	(%0000<<12)!(31*4)	; (exception ($06,sp))
RomTagStr:
		dc.b   	'vzekcc25 0.2 (21.07.2025) PAL',13,10,0,0,'$VER: '
		dc.b   	'vzekcc25 0.2 (21.07.2025) PAL',10
		dc.b   	'Licensed under'
		dc.b   	' CC-BY-NC-SA-3.0-DE AND'
		dc.b   	' CC-BY-NC-SA-3.0 AND'
		dc.b   	' CC-BY-NC-SA-4.0 AND'
		dc.b   	' CC0-1.0',10
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
		dc.b   	' licensed under CC0 1.0 by Nico Bendlin <nico@nicode.net>',10,0
		dcb.b  	(*-RomBase)&%0001,0

;-----------------------------------------------------------------------------
;
;                                ROM code/data
;

RomEntry:
		move.w 	#$2700,sr     	; supervisor mode, IPL = 7
		lea    	($DFF000).L,a6	; _custom
		move.w 	#((~INTF_SETCLR)&$FFFF),(intena,a6)
		move.w 	#((~INTF_SETCLR)&$FFFF),(intreq,a6)
		move.w 	#DMAF_ALL,(dmacon,a6)
		moveq  	#0,d0
InitScreen:
		move.w 	#DISPLAYPAL,(beamcon0,a6)
		move.l 	#((MODE_640!COLORON!INTERLACE)<<16),(bplcon0,a6)
		move.w 	#%0100100,(bplcon2,a6)	; PFP=SP01/SP23/SP45/SP67/PF1
		lea    	(color,a6),a0
		move.w 	#$0210,(a0)
		move.w 	d0,(bpldat,a6)
		lea    	(16*2,a0),a0
		move.l 	#$09BC09AB,(a0)+
		move.l 	#$099908CE,(a0)+
		move.l 	#$08990888,(a0)+
		move.l 	#$088206AC,(a0)+
		move.l 	#$06660665,(a0)+
		move.l 	#$06620654,(a0)+
		move.l 	#$059B0542,(a0)+
		move.l 	#$048A0444,(a0)
InitVector:
		lea    	($BFE001).L,a5    	; _ciaa
		move.b 	#CIAF_LED!CIAF_OVERLAY,(ciaddra,a5)
		bclr.b 	#CIAB_OVERLAY,(a5)	; (ciapra,)
		movea.l	d0,a0
		move.l 	d0,(a0)+	; ZeroLocation
		move.l 	d0,(a0)+	; AbsExecBase
		lea    	(RomExcept,pc),a1
		move.w 	#((RamCoperBase-VecBusError)/4)-1,d1
0$:		move.l 	a1,(a0)+
		dbf    	d1,0$
		move.l 	a0,sp
		lea    	(IntLevel3,pc),a1
		move.l 	a1,(VecIntLevel3).w
CopyCopper:
		lea    	(RomCopper,pc),a1
		move.w 	#((RomImages-RomCopper)/4)-1,d1
0$:		move.l 	(a1)+,(a0)+
		dbf    	d1,0$
MakeImage1:
		ext.l  	d1
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
		move.l 	d1,(a0)+
		moveq  	#(LOGOROWLEN/2)-1,d4
MkImg1Logo:	cmp.w  	#(SCR1HEIGHT-((SCR1HEIGHT-LOGOHEIGHT)/2)),d3
		bhs.w  	MkImg1Fill
		cmp.w  	#((SCR1HEIGHT-LOGOHEIGHT)/2),d3
		blo.w  	MkImg1Fill
		move.l 	(a1)+,(a0)+
		bra.w  	MkImg1Next
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
MkImg1Fill:	move.l 	d1,(a0)+
MkImg1Next:	dbf    	d4,MkImg1Logo
		move.l 	d1,(a0)+
		dbf    	d3,MkImg1Line
		move.l 	(a3)+,d3
		move.w 	(a3),d4
		move.l 	d3,(a0)+
		move.w 	d4,(a0)+
		move.l 	d3,(a0)+
		move.w 	d4,(a0)+
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

InitBltCop:
		move.l 	#(((BC0F_SRCA!BC0F_DEST!ABC!ABNC!ANBC!ANBNC)<<16)!(0)),(bltcon0,a6)
		move.l 	#(((SCR1BPLMOD)<<16)!(SCR1BPLMOD)),(bltamod,a6)
		move.l 	#((($FFFF)<<16)!($FFFF)),(bltafwm,a6)
		move.w 	#$0002,(copcon,a6)	; CDANG (Copper blitter access)
		move.l 	#((RomCop0_1-RomCopper)+RamCoperBase),(cop1lc,a6)
		move.w 	#(INTF_SETCLR!INTF_INTEN!INTF_COPER),(intena,a6)
EnableDMAs:
		move.w 	#(DMAF_SETCLR!DMAF_BLITHOG!DMAF_MASTER!DMAF_RASTER!DMAF_COPPER!DMAF_BLITTER),(dmacon,a6)
WaitForInt:
		; CPU off - wait for interrupt (IntLevel3)
		stop   	#$2200	; supervisor mode, IPL = 2
		bra.b  	WaitForInt

;-----------------------------------------------------------------------------

IntLevel3:
		btst.b 	#INTB_COPER,(intreqr+1,a6)
		beq.b  	1$
		;TODO: handle screen states/switches
		btst.b 	#(15-8),(vposr+0,a6)	; LOL
		beq.b  	0$
		move.l 	#((RomCop1_2L-RomCopper)+RamCoperBase),(cop2lc,a6)
		move.l 	#((RomCop1_1-RomCopper)+RamCoperBase),(cop1lc,a6)
0$:		move.w 	#INTF_COPER,(intreq,a6)
1$:		rte

;-----------------------------------------------------------------------------

RomCopper:
CIR1F_WAIT	EQU	($0001)
CIR2F_BFD	EQU	($8000)

RomCop0_1:
		dc.w	CIR1F_WAIT!$FFDE,$7FFE!CIR2F_BFD
		dc.w	(intreq),(INTF_SETCLR!INTF_COPER)
		dc.w	CIR1F_WAIT!$FFFE,$7FFE!CIR2F_BFD

RomCop1_1:
		dc.w	(color+0*2),$0210
		dc.w	(color+1*2),$0322
		dc.w	(color+2*2),$0432
		dc.w	(color+3*2),$0433
		dc.w	(color+4*2),$0543
		dc.w	(color+5*2),$0654
		dc.w	(color+6*2),$0765
		dc.w	(color+7*2),$0876
		dc.w	(color+8*2),$0A63
		dc.w	(color+9*2),$0B74
		dc.w	(color+10*2),$0A87
		dc.w	(color+11*2),$0B98
		dc.w	(color+12*2),$0CA8
		dc.w	(color+13*2),$0DB9
		dc.w	(color+14*2),$0ECA
		dc.w	(color+15*2),$0FDB
		dc.w	(bplcon0),(MODE_640!(4<<PLNCNTSHFT)!COLORON!INTERLACE)
		dc.w	(diwstrt),$2C81
		dc.w	(diwstop),$2CC1
		dc.w	(ddfstrt),$003C
		dc.w	(ddfstop),$00D4
		dc.w	(bpl1mod),SCR1BPLMOD
		dc.w	(bpl2mod),SCR1BPLMOD
		dc.w   	(copjmp2),0
RomCop1_2U:
		dc.w	(cop2lc+2),((RomCop1_2L-RomCopper)+RamCoperBase)
		dc.w	(bplpt+0*4+0),(Scr1Bpl1Dat0>>16)
		dc.w	(bplpt+0*4+2),(Scr1Bpl1Dat0&$FFFF)
		dc.w	(bplpt+1*4+0),(Scr1Bpl2Dat0>>16)
		dc.w	(bplpt+1*4+2),(Scr1Bpl2Dat0&$FFFF)
		dc.w	(bplpt+2*4+0),(Scr1Bpl3Dat0>>16)
		dc.w	(bplpt+2*4+2),(Scr1Bpl3Dat0&$FFFF)
		dc.w	(bplpt+3*4+0),(Scr1Bpl4Dat0>>16)
		dc.w	(bplpt+3*4+2),(Scr1Bpl4Dat0&$FFFF)
		; CCITT	step #2/2 (bitplane 3/4)
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl3Dat1>>16)
		dc.w	(bltapt+2),(Scr1Bpl3Dat1&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl3Dat0>>16)
		dc.w	(bltdpt+2),(Scr1Bpl3Dat0&$FFFF)
		dc.w	(bltsize),((SCR1HEIGHT<<HSIZEBITS)!(3))
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl4Dat1>>16)
		dc.w	(bltapt+2),(Scr1Bpl4Dat1&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl4Dat0>>16)
		dc.w	(bltdpt+2),(Scr1Bpl4Dat0&$FFFF)
		dc.w	(bltsize),((SCR1HEIGHT<<HSIZEBITS)!(3))
		; CCITT	step #3 (set bottom/right)
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl1Rot1>>16)
		dc.w	(bltapt+2),(Scr1Bpl1Rot1&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl1Rot0>>16)
		dc.w	(bltdpt+2),(Scr1Bpl1Rot0&$FFFF)
		dc.w	(bltsize),((1<<HSIZEBITS)!(3))
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl2Rot1>>16)
		dc.w	(bltapt+2),(Scr1Bpl2Rot1&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl2Rot0>>16)
		dc.w	(bltdpt+2),(Scr1Bpl2Rot0&$FFFF)
		dc.w	(bltsize),((1<<HSIZEBITS)!(3))
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl3Rot1>>16)
		dc.w	(bltapt+2),(Scr1Bpl3Rot1&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl3Rot0>>16)
		dc.w	(bltdpt+2),(Scr1Bpl3Rot0&$FFFF)
		dc.w	(bltsize),((1<<HSIZEBITS)!(3))
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl4Rot1>>16)
		dc.w	(bltapt+2),(Scr1Bpl4Rot1&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl4Rot0>>16)
		dc.w	(bltdpt+2),(Scr1Bpl4Rot0&$FFFF)
		dc.w	(bltsize),((1<<HSIZEBITS)!(3))
	;	dc.w	CIR1F_WAIT!$0000,$0000
	;	dc.w	CIR1F_WAIT!$0000,$0000
	;	dc.w	(intreq),(INTF_SETCLR!INTF_COPER)
		dc.w	CIR1F_WAIT!$FFFE,$7FFE!CIR2F_BFD
RomCop1_2L:
		dc.w	(cop2lc+2),((RomCop1_2U-RomCopper)+RamCoperBase)
		dc.w	(0*4+bplpt+0),(Scr1Bpl1Dat1>>16)
		dc.w	(0*4+bplpt+2),(Scr1Bpl1Dat1&$FFFF)
		dc.w	(1*4+bplpt+0),(Scr1Bpl2Dat1>>16)
		dc.w	(1*4+bplpt+2),(Scr1Bpl2Dat1&$FFFF)
		dc.w	(2*4+bplpt+0),(Scr1Bpl3Dat1>>16)
		dc.w	(2*4+bplpt+2),(Scr1Bpl3Dat1&$FFFF)
		dc.w	(3*4+bplpt+0),(Scr1Bpl4Dat1>>16)
		dc.w	(3*4+bplpt+2),(Scr1Bpl4Dat1&$FFFF)
		; CCITT	step #1 (save top/left)
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl1Dat0>>16)
		dc.w	(bltapt+2),(Scr1Bpl1Dat0&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl1Rot1>>16)
		dc.w	(bltdpt+2),(Scr1Bpl1Rot1&$FFFF)
		dc.w	(bltsize),((1<<HSIZEBITS)!(3))
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl2Dat0>>16)
		dc.w	(bltapt+2),(Scr1Bpl2Dat0&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl2Rot1>>16)
		dc.w	(bltdpt+2),(Scr1Bpl2Rot1&$FFFF)
		dc.w	(bltsize),((1<<HSIZEBITS)!(3))
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl3Dat0>>16)
		dc.w	(bltapt+2),(Scr1Bpl3Dat0&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl3Rot1>>16)
		dc.w	(bltdpt+2),(Scr1Bpl3Rot1&$FFFF)
		dc.w	(bltsize),((1<<HSIZEBITS)!(3))
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl4Dat0>>16)
		dc.w	(bltapt+2),(Scr1Bpl4Dat0&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl4Rot1>>16)
		dc.w	(bltdpt+2),(Scr1Bpl4Rot1&$FFFF)
		dc.w	(bltsize),((1<<HSIZEBITS)!(3))
		; CCITT	step #2/1 (bitplanes 1/2)
		dc.w	CIR1F_WAIT!$FB1C,$7FFE!CIR2F_BFD
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl1Dat1>>16)
		dc.w	(bltapt+2),(Scr1Bpl1Dat1&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl1Dat0>>16)
		dc.w	(bltdpt+2),(Scr1Bpl1Dat0&$FFFF)
		dc.w	(bltsize),((SCR1HEIGHT<<HSIZEBITS)!(3))
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	(bltapt+0),(Scr1Bpl2Dat1>>16)
		dc.w	(bltapt+2),(Scr1Bpl2Dat1&$FFFF)
		dc.w	(bltdpt+0),(Scr1Bpl2Dat0>>16)
		dc.w	(bltdpt+2),(Scr1Bpl2Dat0&$FFFF)
		dc.w	(bltsize),((SCR1HEIGHT<<HSIZEBITS)!(3))
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$0000,$0000
		dc.w	CIR1F_WAIT!$FFFE,$7FFE!CIR2F_BFD

;-----------------------------------------------------------------------------

RomImages:

	INCLUDE	imagedat.i

;-----------------------------------------------------------------------------
;
;                                 ROM footer
;

RomTagEnd:
		dcb.b	ROM_SIZE-(2*4)-(8*2)-(*-RomBase),ROM_FILL
RomFooter:
		dc.l 	$00000000	; Kickstart ROM checksum
		dc.l 	ROM_SIZE 	; Kickstart ROM size
		dc.b 	0,24	; Spurious Interrupt
		dc.b 	0,25	; Autovector Level 1 (TBE, DSKBLK, SOFTINT)
		dc.b 	0,26	; Autovector Level 2 (PORTS)
		dc.b 	0,27	; Autovector Level 3 (COPER, VERTB, BLIT)
		dc.b 	0,28	; Autovector Level 4 (AUD2, AUD0, AUD3, AUD1)
		dc.b 	0,29	; Autovector Level 5 (RBF, DSKSYNC)
		dc.b 	0,30	; Autovector Level 6 (EXTER, INTEN)
		dc.b 	0,31	; Autovector Level 7 (NMI)

	PRINTT	'ROM free:'
	PRINTV	RomFooter-RomTagEnd

	END
