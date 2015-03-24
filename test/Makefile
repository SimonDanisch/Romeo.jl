## Makefile in Romeo/test

PAMDIR=/home/alain/test/BigData/
JULIATRY=$(PAMDIR)/JULIA-TRY
JULIAENV=$(PAMDIR)/JULIA-ENV
JULIAPGM=Julia4

DOCUTILDIR=../src/docUtil

RomeoVolume.jl: $(JULIATRY)/RomeoVolume.jl
	cat $< |cpif $@

$(DOCUTILDIR)/RomeoLib.jl: $(JULIATRY)/RomeoLib.jl
	cat $< |cpif $@

.PHONY: run runD runDI runSingle runSingleD runSingleI progs \
        editTest2
progs :  RomeoVolume.jl $(DOCUTILDIR)/RomeoLib.jl

run:         progs 
	$(JULIAPGM) RomeoVolume.jl

runD:         progs 
	$(JULIAPGM) RomeoVolume.jl --debug=61

runDI:         progs 
	$(JULIAPGM) RomeoVolume.jl --debug=61 -i


runSingle:   progs 
	$(JULIAPGM) RomeoVolume.jl --cube

runSingleD:  progs 
	$(JULIAPGM) RomeoVolume.jl --cube --debug=61

runSingleDI:  progs 
	$(JULIAPGM) RomeoVolume.jl --cube --img --debug=61


editTest2:
        # barely working version of SD's runtest.jl (my mods+documentation)
	$(JULIAPGM) runtestsDoc.jl	

# -exemples found in the upstream (S.Danisch) git tree


# --exemples sent by S.Danisch (and working)
.PHONY: runtt synchRot editTest gridImg
#    show surface with mouse actions (rotations etc)
runtt : testest.jl
	$(JULIAPGM) testest.jl
# synch mouse actions in 2 subscreens with surface graphs
synchRot: exempleSDMeshCam3.jl
	$(JULIAPGM) exempleSDMeshCam3.jl

# edit test
editTest: runtests.jl
        # very slow mouse action, keyboard keys not all working 
        # CTL-ENTER to eval formula
	$(JULIAPGM) runtests.jl	
gridImg: simple_display_grid.jl
	$(JULIAPGM) simple_display_grid.jl

#### non working examples
# felix.jl
#	LoadError: MethodError: `edit` has no method matching edit(::Dict{Symbol,Any})

# Non intended to work as is
#exempleSDMeshCam2.jl
#exempleSDMeshCam3.jl