# GNU Make: <https://www.gnu.org/software/make/>
# vasm    : <http://www.compilers.de/vasm.html>
# romtool : <https://pypi.org/project/amitools/>

AMIGA_TOOLCHAIN ?= /opt/amiga
VASM ?= $(AMIGA_TOOLCHAIN)/bin/vasmm68k_mot
NDK_INCLUDE ?= $(AMIGA_TOOLCHAIN)/m68k-amigaos/ndk-include
VASM_OPTS ?= -quiet -wfail -x -I$(NDK_INCLUDE)
ROMTOOL ?= /usr/bin/env romtool
WINE ?= /usr/bin/env WINEDEBUG=-all wine
WINE_PWD ?= $(shell $(WINE) start /d $(shell pwd) /wait /b CMD /c CD)
WINUAE_ZIP ?= WinUAE6000.zip
WINUAE_URL ?= https://download.abime.net/winuae/releases/$(WINUAE_ZIP)
PYTHON_BIN ?= /usr/bin/env python3

all: vzekcc25-pal.rom kickstart-vzekcc25-pal.adf

.PHONY: all \
	check check-pal \
	clean distclean \
	test test-pal test-pal-ntsc \
	winuae-beta-just-shut-up

check: check-pal

check-pal: vzekcc25-pal.rom
	-$(ROMTOOL) copy --fix-checksum $< $<
	$(ROMTOOL) info $<

clean:
	rm -f vzekcc25-pal.rom vzekcc25-pal.rom.lst kickstart-vzekcc25-pal.adf
	rm -f imagedat.i

distclean: clean
	rm -rf .idea
	rm -rf winuae

imagedat.i: vzekc-cc2025-invite-ocs-logo.png vzekc-cc2025-invite-ocs-poster.png
	$(PYTHON_BIN) imagedat.py

kickstart-vzekcc25-pal.adf : kickstart.asm vzekcc25-pal.rom
	$(VASM) -Fbin $(VASM_OPTS) -o $@ $<

vzekcc25-pal.rom : vzekcc25.asm imagedat.i
	$(VASM) -Fbin $(VASM_OPTS) -L $@.lst -Lni -Lns -o $@ $<

winuae/$(WINUAE_ZIP):
	mkdir -p winuae && cd winuae && wget $(WINUAE_URL)

winuae/winuae.exe: | winuae/$(WINUAE_ZIP)
	cd winuae && unzip $(WINUAE_ZIP)

WINUAE_GUI ?= false
WINUAE_DBG ?= false
WINUAE_OPT_GUI = \
	-s use_gui=$(WINUAE_GUI) \
	-s use_debugger=$(WINUAE_DBG) \
	-s win32.start_not_captured=$(WINUAE_DBG) \
	-s win32.nonotificationicon=true \

WINUAE_WIDTH ?= 1920
WINUAE_HEIGHT ?= 1080
WINUAE_API ?= direct3d
WINUAE_API_OPT ?= hardware
WINUAE_FULLSCREEN ?= $(if $(WINUAE_DBG:true=),true,false)
WINUAE_OVERSCAN ?= $(if $(WINUAE_DBG:true=),tv_standard,ultra_csync)
WINUAE_OPT_GFX = \
	-s gfx_display=0 \
	-s gfx_width=$(WINUAE_WIDTH) \
	-s gfx_height=$(WINUAE_HEIGHT) \
	-s gfx_width_windowed=784 \
	-s gfx_height_windowed=636 \
	-s gfx_lores=false \
	-s gfx_resolution=hires \
	-s gfx_lores_mode=normal \
	-s gfx_flickerfixer=false \
	-s gfx_linemode=double \
	-s gfx_center_horizontal=none \
	-s gfx_center_vertical=none \
	-s gfx_api=$(WINUAE_API) \
	-s gfx_api_options=$(WINUAE_API_OPT) \
	-s gfx_overscanmode=$(WINUAE_OVERSCAN) \
	-s gfx_fullscreen_amiga=$(WINUAE_FULLSCREEN) \

WINUAE_OPT_EMU = \
	-s boot_rom_uae=disabled \
	-s uaeboard=disabled_off \
	-s genlock=false \
	-s cycle_exact=true \
	-s display_optimizations=none \

WINUAE_OPT_CPU = \
	-s cpu_type=68000 \
	-s cpu_model=68000 \
	-s cpu_speed=real \
	-s cpu_multiplier=2 \
	-s cpu_compatible=true \
	-s cpu_24bit_addressing=true \
	-s cpu_cycle_exact=true \
	-s cpu_memory_cycle_exact=true \

WINUAE_OPT_A1K = \
	-s chipset=ocs \
	-s fastmem_size=0 \
	-s chipmem_size=0 \
	-s chipset_compatible=A1000 \
	-s a1000ram=true \
	-s ics_agnus=false \
	-s agnusmodel=a1000 \
	-s denisemodel=a1000 \

test: test-pal

test-pal: vzekcc25-pal.rom | winuae/winuae.exe
	cd winuae && $(WINE) winuae.exe \
		$(WINUAE_OPT_GUI) $(WINUAE_OPT_GFX) \
		$(WINUAE_OPT_EMU) $(WINUAE_OPT_CPU) \
		$(WINUAE_OPT_A1K) -s ntsc=false \
		-s kickstart_rom_file='$(WINE_PWD)\$<'

test-pal-ntsc: vzekcc25-pal.rom | winuae/winuae.exe
	cd winuae && $(WINE) winuae.exe \
		$(WINUAE_OPT_GUI) $(WINUAE_OPT_GFX) \
		$(WINUAE_OPT_EMU) $(WINUAE_OPT_CPU) \
		$(WINUAE_OPT_A1K) -s ntsc=true \
		-s kickstart_rom_file='$(WINE_PWD)\$<'

winuae-beta-just-shut-up:
	$(WINE) reg add 'HKEY_CURRENT_USER\Software\Arabuusimiehet\WinUAE' \
		/v 'Beta_Just_Shut_Up' /t REG_DWORD /d 68010 /f /reg:32

