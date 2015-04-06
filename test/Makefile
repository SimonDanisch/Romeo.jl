## Makefile in Romeo/test

PAMDIR=/home/alain/test/BigData/
JULIATRY=$(PAMDIR)/JULIA-TRY
JULIAENV=$(PAMDIR)/JULIA-ENV
JULIAPGM=Julia4

DOCUTILDIR=../src/docUtil
DOCUNITTEST=unitTests

RomeoVolume.jl: $(JULIATRY)/RomeoVolume.jl
	cat $< |cpif $@

$(DOCUTILDIR)/RomeoLib.jl: $(JULIATRY)/RomeoLib.jl
	cat $< |cpif $@

$(DOCUTILDIR)/DebugTools.jl: $(JULIATRY)/DebugTools.jl
	cat $< |cpif $@

$(DOCUTILDIR)/MatrixMathPlus.jl: $(JULIATRY)/MatrixMathPlus.jl
	cat $< |cpif $@

$(DOCUTILDIR)/SubScreens.jl: $(JULIATRY)/SubScreens.jl
	cat $< |cpif $@

$(DOCUTILDIR)/SimpleSubScreens.jl: $(JULIATRY)/SimpleSubScreens.jl
	cat $< |cpif $@

$(DOCUTILDIR)/XtraRenderObjOGL.jl: $(JULIATRY)/XtraRenderObjOGL.jl
	cat $< |cpif $@

$(DOCUTILDIR)/ROGeomOps.jl: $(JULIATRY)/ROGeomOps.jl
	cat $< |cpif $@

$(DOCUTILDIR)/VirtualOGLGeom.jl: $(JULIATRY)/VirtualOGLGeom.jl
	cat $< |cpif $@

$(DOCUTILDIR)/TBCompletedM.jl: $(JULIATRY)/TBCompletedM.jl
	cat $< |cpif $@

$(DOCUTILDIR)/Changelog: $(JULIAENV)/Changelog
	cat $< |cpif $@

$(DOCUNITTEST)/testSubScreen.jl :$(JULIATRY)/testSubScreen.jl
	cat $< |cpif $@

$(DOCUNITTEST)/testLumberjack.jl :$(JULIATRY)/testLumberjack.jl
	cat $< |cpif $@

$(DOCUNITTEST)/TestOGLGeom.jl :$(JULIATRY)/TestOGLGeom.jl
	cat $< |cpif $@

$(DOCUNITTEST)/testVirtOGLGeom.jl:$(JULIATRY)/testVirtOGLGeom.jl
	cat $< |cpif $@



.PHONY: run runD runDI runSingle runSingleD runSingleI progs tests progtests\
        editTest2

progs :  RomeoVolume.jl \
        $(DOCUTILDIR)/RomeoLib.jl \
        $(DOCUTILDIR)/DebugTools.jl \
        $(DOCUTILDIR)/TBCompletedM.jl \
        $(DOCUTILDIR)/MatrixMathPlus.jl \
        $(DOCUTILDIR)/SubScreens.jl \
        $(DOCUTILDIR)/SimpleSubScreens.jl \
        $(DOCUTILDIR)/XtraRenderObjOGL.jl \
	$(DOCUTILDIR)/VirtualOGLGeom.jl \
	$(DOCUTILDIR)/ROGeomOps.jl \
        $(DOCUTILDIR)/Changelog

progtests: $(DOCUNITTEST)/testSubScreen.jl \
	    $(DOCUNITTEST)/testLumberjack.jl \
	    $(DOCUNITTEST)/TestOGLGeom.jl \
	    $(DOCUNITTEST)/testVirtOGLGeom.jl


run:         progs 
	$(JULIAPGM) RomeoVolume.jl --log=/tmp/RomeoLumber01.log

runD:         progs 
	$(JULIAPGM) RomeoVolume.jl --log=/tmp/RomeoLumber01.log --debugAbs=61 --debugWin=1

runDI:         progs 
	$(JULIAPGM) RomeoVolume.jl -i --log=/tmp/RomeoLumber01.log --debugAbs=61 --debugWin=1


runSingle:   progs 
	$(JULIAPGM) RomeoGridSimple.jl --log=/tmp/RomeoLumber01.log --cube

runSingleD:  progs 
	$(JULIAPGM) RomeoGridSimple.jl --cube --debugAbs=61 --debugWin=1

runSingleDI:  progs 
	$(JULIAPGM) RomeoGridSimple.jl --cube --img --debugAbs=61 --debugWin=1


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

# Non intended to work as is (example snippets)
#exempleSDMeshCam2.jl
#exempleSDMeshCam3.jl