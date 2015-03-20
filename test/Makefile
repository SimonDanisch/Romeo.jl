## Makefile in Romeo/test

PAMDIR=/home/alain/test/BigData/
JULIATRY=$(PAMDIR)/JULIA-TRY
JULIAENV=$(PAMDIR)/JULIA-ENV

DOCUTILDIR=../src/docUtil

RomeoVolume.jl: $(JULIATRY)/RomeoVolume.jl
	cat $< |cpif $@

$(DOCUTILDIR)/RomeoLib.jl: $(JULIATRY)/RomeoLib.jl
	cat $< |cpif $@

.PHONY: run runSingle progs

progs: RomeoVolume.jl $(DOCUTILDIR)/RomeoLib.jl

run:  RomeoVolume.jl $(DOCUTILDIR)/RomeoLib.jl
	Julia4 RomeoVolume.jl

runSingle:   RomeoVolume.jl $(DOCUTILDIR)/RomeoLib.jl
	Julia4 RomeoVolume.jl --cube