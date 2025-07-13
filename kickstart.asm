	IDNT	KICKSTRT

Sector0:
		dc.b   	'KICK'
		dcb.b  	512-(*-Sector0),0
Sector1:
	INCBIN	vzekcc25-pal.rom

		dcb.b  	2*80*11*512-(*-Sector0),0

	END
