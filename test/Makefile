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

progs :  RomeoVolume.jl $(DOCUTILDIR)/RomeoLib.jl

run:         progs 
	Julia4 RomeoVolume.jl

runSingle:   progs 
	Julia4 RomeoVolume.jl --cube

runSingleD:  progs 
	Julia4 RomeoVolume.jl --cube --debug=60

runSingleDI:  progs 
	Julia4 RomeoVolume.jl --cube --Img --debug=60
