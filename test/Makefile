## Makefile in Romeo/test

PAMDIR=/home/alain/test/BigData/
JULIATRY=$(PAMDIR)/JULIA-TRY
JULIAENV=$(PAMDIR)/JULIA-ENV
JULIAPGM=Julia4

DOCUTILDIR=../src/docUtil
DOCUNITTEST=unitTests

ifeq ($(STRIP),)
  STRIPLINECMD=cat
else
  STRIPLINECMD=egrep -v -E "[-][-]line [0-9]+ --.*from :" 
endif

.PHONY:help

help:
	@echo "set var STRIP when source line numbering not needed (for git)"
	@echo make STRIP=YES....
	echo STRIPLINECMD = $(STRIPLINECMD)

RomeoVolume.jl: $(JULIATRY)/RomeoVolume.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/RomeoLib.jl: $(JULIATRY)/RomeoLib.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/DocCompat.jl: $(JULIAENV)/DocCompat.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/ManipStreams.jl: $(JULIAENV)/ManipStreams.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/RomeoLibSimple.jl: $(JULIATRY)/RomeoLibSimple.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/DebugTools.jl: $(JULIATRY)/DebugTools.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/MatrixMathPlus.jl: $(JULIATRY)/MatrixMathPlus.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/SubScreens.jl: $(JULIATRY)/SubScreens.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/Connectors.jl: $(JULIATRY)/Connectors.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/SimpleSubScreens.jl: $(JULIATRY)/SimpleSubScreens.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/XtraRenderObjOGL.jl: $(JULIATRY)/XtraRenderObjOGL.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/ROGeomOps.jl: $(JULIATRY)/ROGeomOps.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/VirtualOGLGeom.jl: $(JULIATRY)/VirtualOGLGeom.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/TBCompletedM.jl: $(JULIATRY)/TBCompletedM.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/ParseXMLSubscreen.jl: $(JULIATRY)/ParseXMLSubscreen.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/SemXMLSubscreen.jl: $(JULIATRY)/SemXMLSubscreen.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/subscreenSchema.xsd: $(JULIATRY)/subscreenSchema.xsd
	cat $< |cpif $@

subscreenSpec.xml: $(JULIATRY)/subscreenSpec.xml
	cat $< |cpif $@

subscreenSpec2.xml: $(JULIATRY)/subscreenSpec2.xml
	cat $< |cpif $@

$(DOCUTILDIR)/Changelog: $(JULIAENV)/Changelog
	cat $< |cpif $@

$(DOCUNITTEST)/testSubScreen.jl :$(JULIATRY)/testSubScreen.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUNITTEST)/testLumberjack.jl :$(JULIATRY)/testLumberjack.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUNITTEST)/TestOGLGeom.jl :$(JULIATRY)/TestOGLGeom.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUNITTEST)/testVirtOGLGeom.jl:$(JULIATRY)/testVirtOGLGeom.jl
	$(STRIPLINECMD) $< |cpif $@



.PHONY: run run3D runXML runD runDI runSingle runSingle3D runSingleD runSingleI \
	eprogs tests progtests \
        editTest2

progs :  RomeoVolume.jl \
        $(DOCUTILDIR)/RomeoLib.jl \
        $(DOCUTILDIR)/RomeoLibSimple.jl \
        $(DOCUTILDIR)/DebugTools.jl \
        $(DOCUTILDIR)/TBCompletedM.jl \
        $(DOCUTILDIR)/MatrixMathPlus.jl \
        $(DOCUTILDIR)/SubScreens.jl \
        $(DOCUTILDIR)/Connectors.jl \
        $(DOCUTILDIR)/SimpleSubScreens.jl \
        $(DOCUTILDIR)/XtraRenderObjOGL.jl \
	$(DOCUTILDIR)/VirtualOGLGeom.jl \
	$(DOCUTILDIR)/ROGeomOps.jl \
        $(DOCUTILDIR)/Changelog \
        $(DOCUTILDIR)/ParseXMLSubscreen.jl \
        $(DOCUTILDIR)/SemXMLSubscreen.jl \
        $(DOCUTILDIR)/ManipStreams.jl \
        $(DOCUTILDIR)/DocCompat.jl \
        $(DOCUTILDIR)/subscreenSchema.xsd 


progtests: $(DOCUNITTEST)/testSubScreen.jl \
	    $(DOCUNITTEST)/testLumberjack.jl \
	    $(DOCUNITTEST)/TestOGLGeom.jl \
	    $(DOCUNITTEST)/testVirtOGLGeom.jl


run:         progs 
	$(JULIAPGM) RomeoVolume.jl --log=/tmp/RomeoLumber01.log

runXML:      progs subscreenSpec.xml
	$(JULIAPGM) RomeoVolume.jl --xml=subscreenSpec.xml --log=/tmp/RomeoLumber01.log

runXML2:      progs subscreenSpec2.xml
	$(JULIAPGM) RomeoVolume.jl --xml=subscreenSpec2.xml --log=/tmp/RomeoLumber01.log

run3D:       progs 
	$(JULIAPGM) RomeoVolume.jl --dim=3 --log=/tmp/RomeoLumber01.log

runD:         progs 
	$(JULIAPGM) RomeoVolume.jl --log=/tmp/RomeoLumber01.log --debugAbs=61 --debugWin=1

runDI:         progs 
	$(JULIAPGM) RomeoVolume.jl -i --log=/tmp/RomeoLumber01.log --debugAbs=61 --debugWin=1


runSingle:   progs 
	$(JULIAPGM) RomeoGridSimple.jl --log=/tmp/RomeoLumber01.log --cube

runSingle3D:   progs 
	$(JULIAPGM) RomeoGridSimple.jl  --log=/tmp/RomeoLumber01.log --dim3D

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