## Makefile in Romeo/test

############## These are specific to the dev environment and should be adapted 
PAMDIR=/home/alain/test/BigData/
JULIATRY=$(PAMDIR)/JULIA-TRY
JULIAENV=$(PAMDIR)/JULIA-ENV
JULIAPGM=Julia4

############## End of area needing adaptation 

DOCUTILDIR=../src/docUtil
TOOLSDIR=tools
DOCXMLSCR=../src/XMLScreens
DOCXROMEOSRC=../src/
DOCUNITTEST=unitTests

CMDXMLVALID=tools/xmlValid

TSTAMP=.strip.timestamp

ifeq ($(STRIP),)
  STRIPLINECMD=cat
else
  STRIPLINECMD=egrep -v -E "[-][-]line [0-9]+ --.*from :" 
endif

.PHONY:help ts

help:
	@echo "set var STRIP when source line numbering not needed (for git)"
	@echo make STRIP=YES....
	echo STRIPLINECMD = $(STRIPLINECMD)

	@echo after switch to GLVisualize
	@echo "use runXML   -- as there is no non XML program provided"
	@echo "             -- not decided (yet?) to provide a non XML (ie API) example "

ts:
	echo TIME STAMP `date` >  $(TSTAMP)

$(DOCXROMEOSRC)/Romeo.jl : $(JULIATRY)/Romeo.jl  $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

RomeoMain.jl: $(JULIATRY)/RomeoMain.jl  $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCXMLSCR)/RomeoLib.jl: $(JULIATRY)/RomeoLib.jl  $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCUTILDIR)/ManipStreams.jl: $(JULIAENV)/ManipStreams.jl  $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@


$(DOCXMLSCR)/DebugTools.jl: $(JULIATRY)/DebugTools.jl     $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCXMLSCR)/MatrixMathPlus.jl: $(JULIATRY)/MatrixMathPlus.jl    $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCXMLSCR)/SubScreens.jl: $(JULIATRY)/SubScreens.jl     $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCXMLSCR)/Connectors.jl: $(JULIATRY)/Connectors.jl     $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@


$(DOCXMLSCR)/XtraRenderObjOGL.jl: $(JULIATRY)/XtraRenderObjOGL.jl  $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCXMLSCR)/ROGeomOps.jl: $(JULIATRY)/ROGeomOps.jl   $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCXMLSCR)/VirtualOGLGeom.jl: $(JULIATRY)/VirtualOGLGeom.jl   $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCXMLSCR)/TBCompletedM.jl: $(JULIATRY)/TBCompletedM.jl   $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCXMLSCR)/ParseXMLSubscreen.jl: $(JULIATRY)/ParseXMLSubscreen.jl   $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCXMLSCR)/SemXMLSubscreen.jl: $(JULIATRY)/SemXMLSubscreen.jl   $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCXMLSCR)/Constants.jl: $(JULIATRY)/Constants.jl   $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCXMLSCR)/subscreenSchema.xsd: $(JULIATRY)/subscreenSchema.xsd
	cat $< |cpif $@

########## TEST MATERIAL

subscreenSpec.xml: $(JULIATRY)/subscreenSpec.xml
	cat $< |cpif $@

subscreenSpec2.xml: $(JULIATRY)/subscreenSpec2.xml
	cat $< |cpif $@

#   provide data (code) referenced in subscreenSpec.xml
#   via julia processing instruction (in xml parlance)
SubScreensModule.jl:  $(JULIATRY)/SubScreensModule.jl
	$(STRIPLINECMD) $< |cpif $@

$(DOCUNITTEST)/testSubScreen.jl :$(JULIATRY)/testSubScreen.jl  $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCUNITTEST)/testLumberjack.jl :$(JULIATRY)/testLumberjack.jl  $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCUNITTEST)/TestOGLGeom.jl :$(JULIATRY)/TestOGLGeom.jl  $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

$(DOCUNITTEST)/testVirtOGLGeom.jl:$(JULIATRY)/testVirtOGLGeom.jl  $(TSTAMP)
	$(STRIPLINECMD) $< |cpif $@

#########  TOOLS

$(TOOLSDIR)/xmlValid:~/bin/xmlValid
	cat $< |cpif $@

########  INFORMATION
$(DOCXMLSCR)/Changelog: $(JULIAENV)/Changelog
	cat $< |cpif $@

#################### INSTALL TARGETS ##################"

.PHONY: run  runXML runXMLD  \
	eprogs tests progtests \
        editTest2

# Note that SubScreensModule.jl is here for tests (used in subscreenSpec2 and RomeoMain)
progs :  RomeoMain.jl subscreenSpec.xml \
         SubScreensModule.jl\
	$(DOCXROMEOSRC)/Romeo.jl \
        $(DOCXMLSCR)/RomeoLib.jl \
        $(DOCXMLSCR)/DebugTools.jl \
        $(DOCXMLSCR)/TBCompletedM.jl \
        $(DOCXMLSCR)/MatrixMathPlus.jl \
        $(DOCXMLSCR)/SubScreens.jl \
        $(DOCXMLSCR)/Connectors.jl \
        $(DOCXMLSCR)/XtraRenderObjOGL.jl \
	$(DOCXMLSCR)/VirtualOGLGeom.jl \
	$(DOCXMLSCR)/ROGeomOps.jl \
        $(DOCXMLSCR)/Changelog \
        $(DOCXMLSCR)/ParseXMLSubscreen.jl \
        $(DOCXMLSCR)/SemXMLSubscreen.jl \
        $(DOCXMLSCR)/Constants.jl \
        $(DOCUTILDIR)/ManipStreams.jl \
        $(DOCXMLSCR)/subscreenSchema.xsd \
	$(TOOLSDIR)/xmlValid

progtests: $(DOCUNITTEST)/testSubScreen.jl \
	    $(DOCUNITTEST)/testLumberjack.jl \
	    $(DOCUNITTEST)/TestOGLGeom.jl \
	    $(DOCUNITTEST)/testVirtOGLGeom.jl \
	    $(TOOLSDIR)/xmlValid

#################### TEST TARGETS ##################"

run:         runXML 
	$(JULIAPGM) RomeoMain.jl --log=/tmp/RomeoLumber01.log

./PHONY : validXML  validXML2  validXML3 validXML4 
validXML: subscreenSpec.xml  $(DOCXMLSCR)/subscreenSchema.xsd
	$(CMDXMLVALID) subscreenSpec.xml  $(DOCXMLSCR)/subscreenSchema.xsd

validXML2:subscreenSpec2.xml  $(DOCXMLSCR)/subscreenSchema.xsd
	$(CMDXMLVALID) subscreenSpec2.xml  $(DOCXMLSCR)/subscreenSchema.xsd

validXML3:subscreenSpec3.xml  $(DOCXMLSCR)/subscreenSchema.xsd
	$(CMDXMLVALID) subscreenSpec3.xml  $(DOCXMLSCR)/subscreenSchema.xsd

validXML4:subscreenSpec4.xml  $(DOCXMLSCR)/subscreenSchema.xsd
	$(CMDXMLVALID) subscreenSpec4.xml  $(DOCXMLSCR)/subscreenSchema.xsd

runXML:      progs subscreenSpec.xml
	$(JULIAPGM) RomeoMain.jl --xml=subscreenSpec.xml --log=/tmp/RomeoLumber01.log

runXMLD:      progs subscreenSpec.xml
	$(JULIAPGM) RomeoMain.jl --debugRLib=0xFF --xml=subscreenSpec.xml --log=/tmp/RomeoLumber01.log

runXML2:      progs subscreenSpec2.xml
	$(JULIAPGM) RomeoMain.jl --debugRLib=0x00 --xml=subscreenSpec2.xml --log=/tmp/RomeoLumber01.log

runXML3:      progs subscreenSpec3.xml
	$(JULIAPGM) RomeoMain.jl --debugRLib=0x00 --xml=subscreenSpec3.xml --log=/tmp/RomeoLumber01.log

runXML4:      progs subscreenSpec4.xml
	$(JULIAPGM) RomeoMain.jl --debugRLib=0x00 --xml=subscreenSpec4.xml --log=/tmp/RomeoLumber01.log


editTest2:
        # barely working version of SD's runtest.jl (my mods+documentation)
	$(JULIAPGM) runtestsDoc.jl	


# tests  : simple tests using GLVisualize
.PHONY: testRTM3D testRTM2D

 testRTM3D:
	$(JULIAPGM) RomeoTestMini.jl	

 testRTM2D:
	$(JULIAPGM) RomeoTestMini.jl	aa bb

# -EXEMPLES found in the upstream (S.Danisch) git tree

# --EXEMPLES sent by S.Danisch (and working  -- before swich to GLVisualize)
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

#### NON WORKING EXAMPLES
# felix.jl
#	LoadError: MethodError: `edit` has no method matching edit(::Dict{Symbol,Any})

# Non intended to work as is (example snippets)
#exempleSDMeshCam2.jl
#exempleSDMeshCam3.jl