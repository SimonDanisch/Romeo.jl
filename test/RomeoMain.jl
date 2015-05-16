using Lumberjack

using Romeo

# try to avoid the numerous "deprecated warnings/messages"
using ManipStreams
(os,ns) =  redirectNewFWrite("/tmp/julia.redirected")

using GLVisualize, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, ColorTypes, FileIO, ImageIO

using GeometryTypes
using TBCompletedM
using SubScreens
using Connectors

    #  Loading GLFW opens the window
using Compat
using LightXML

using  XtraRenderObjOGL
using RomeoLib

using ParseXMLSubscreen
using SemXMLSubscreen
using ColorTypes

using SubScreensModule  # this is a module of "user functions" added for testing

@doc """ This function uses the XML interface to define a screen organized
         into subscreens. 
         It returns :
             a) the subscreen tree for visualization
             b) the symbol table member builtDict of subscreenContext () 
     """  ->
function init_graph_gridXML(onlyImg::Bool, plotDim=2, xml="")
   # Here we need to read the XML and do whatever is needed
   # We have moved this before the definition of the functions below
   # because of the definition of plt below, which requires doPlot2D and
   # doPlot3D. This is also a good test of our parse strategy for XML chunks

   xdoc = parse_file(xml)
   parseTree = acDoc(xdoc)
   sc = subscreenContext()

   # Now, we want to integrate functions defined programmatically here
   # and others which come from the XML subscreen description.
   #
   # First, process the inline xml processing instructions
   xmlJuliaImport(parseTree,sc)
   


   # here we have a rather stringent test: doPlot2D and doPlot3D are 
   # defined in the code inlined in XML (in module SubScreensInline)

   # Since it is created by parse, the module SubScreensInline is known
   # inside the context of the module specified when calling parse in 
   # SemXMLSubscreen.processInline. The function 
   # SemXMLSubscreen.__init__() provides the special module Main.xmlNS
   # for this context.
   try
      SubScreensInline =  xmlNS.SubScreensInline
      println("names module xmlNS", names(xmlNS))
      println("names module SubScreensInline", names(SubScreensInline))
   catch
      println("Information : xmlNS.SubScreensInline not defined")
   end

   # Other functions are provided by the module SubScreensModule
   # in file SubScreensModule.jl
   # For testing purposes, this program mixes the two:
   #       subscreenSpec2.xml: uses import tag and loads from SubScreensModule
   #       subscreenSpec.xml:  uses inline tag and loads from SubScreensInline (not a file!)

   plt = plotDim==2 ? SubScreensModule.doPlot2D : SubScreensModule.doPlot3D

   # put the cat all over the place!!! Example in GLVisualize/test_image.jl
   pic = (sc::Screen,cam::GLAbstraction.Camera)  -> file"pic.jpg"

   # volume : try with a cube (need to figure out how to make this)
   cube = (sc::Screen,cam::GLAbstraction.Camera)-> mkCube(sc,cam)

   # color
   # Unable to convert this function to GLVisualize
   function doColorChooser(sc::Screen,cam::GLAbstraction.Camera)
          TBCompleted (ColorTypes.AlphaColorValue( 
                       ColorTypes.RGB24(0xE0,0x10,0x10), float32(0.5)),
                       nothing, Dict{Symbol,Any}(:doColorChooser=> true))
   end
   colorBtn = doColorChooser

   # edit
   # this is an oversimplification!! (look at exemple!!)
   function doEdit(sc::Screen,cam::GLAbstraction.Camera)
     "barplot = Float32[(sin(i/10f0) + cos(j/2f0))/4f0 \n for i=1:10, j=1:10]\n"
   end
   # This is a table of provided functions, other have been already found when
   # parsing the xml
   fnDict = Dict{AbstractString,Function}("doEdit"       => cube, 
                                          "doColorBtn"   => plt, 
                                          "doCube"       => pic, 
                 			  "doPic"        => pic, 
                                          "doPlot"       => plt )
   # We insert these definitions in the namespace use by xml
   insertXMLNamespace(fnDict)
   println("After insertXMLNamespace names in Main.xmlNS:",names(Main.xmlNS))
   # compute the semantics based on the AST
   vizObj = buildFromParse( parseTree, sc)

   # in case there are  inits specified in XML tags ,
   # (for instance to build signals):
    performInits(sc.builtDict)

   return (vizObj,sc.builtDict)
end  
@doc """
       Does the real work, main only deals with the command line options.
       - init_glutils    :initialization functions (see the GL* libraries)
       - init_graph_grid :prepare a description of the subscreens
       - init_romeo      :construct the subscreens, use the description
                          of subscreens to actually build them (calls visualize)
     """ ->
function realMain(onlyImg::Bool; pcamSel=true, plotDim=2,  xml::String="")
   init_glutils()
   (vizObjSC, bDict)   =        init_graph_gridXML(onlyImg, plotDim, xml)
   println("Entering  init_romeo")
   init_romeo( vizObjSC; pcamSel = pcamSel, builtDict= bDict)

   println("Entering  interact_loop")
   haskey( bDict, (:signalFnList,:list)) ? interact_loop(bDict) : interact_loop()
end

# parse arguments, so that we have some flexibility to vary tests on the 
# command line.
using ArgParse
function main(args)
     s = ArgParseSettings(description = "Test of Romeo with grid of objects")   
     @add_arg_table s begin
       "--dim"
               help="Set to 2 or 3 for 2D or 3D plot"
               arg_type = Int
       "--img","-i"   
               help="Use image instead of other graphics/scenes"
               action = :store_true
       "--xml","-x"
               help="enter the filename of the XML subscreen description"
               arg_type = String
      "--ortho", "-o"       
               help ="Use orthographic camera instead of perspective"
               action = :store_true
       "--log","-l"
               help ="Use lumberjack log"
               arg_type = String
       "--debugRLib"
               help="show debugging output from RomeoLib"
               arg_type = Int
       "--debugSC"
               help="show debugging output from SubScreens"
               arg_type = Int
       "--debugSX"
               help="show debugging output from SemXMLSubscreen"
               arg_type = Int

     end    

     s.epilog = """
       RomeoLib debug levels (ORed bit values):
           0x01: Show information about user provided function calls
              2: Show debugging information related to pushing onto renderlist
              4: Debug connector
              8: Debug calls to visualize
           0x10: Show progress in fnWalk1 functions (walk subscreen tree)
           0x20: Show progress in fnWalk2 functions (walk subscreen tree)
           0x40: Show progress in fnWalk3 functions (walk subscreen tree)
           0x80: Show progress in fnWalk4 functions (walk subscreen tree)

       SubScreens debug levels (ORed bit values):
           0x01: Show progress in treeWalk
              2: Show calls of user  functions
              4: Show iterations to cover children

       SemXMLSubscreen debug levels (ORed bit values):
           0x01: Show steps in syntax recognition
              2: Show final AST
              4: Show state transitions when state automata use fn. stateTrans
              8: Show steps in semantics (transition from XML to actions 
                      on subscreen tree)
           0x10: Show steps in subscreen tree indexing or manipulation
           0x20: Debug julia code inclusion and referencing
           0x40: Debug signal for allowing RenderObjects to receive specialized signals

     """
    parsed_args = parse_args(s) # the result is a Dict{String,Any}

    onlyImg        = parsed_args["img"]
    pcamSel        = !parsed_args["ortho"]
    plotDim        = (parsed_args["dim"] != nothing) ?  parsed_args["dim"] : 2

    xml =  parsed_args["xml"] != nothing ? parsed_args["xml"] : ""

    if parsed_args["log"] != nothing
          logFileName = parsed_args["log"]
          logFileName = length(logFileName) < 5 ? "/tmp/RomeoLumber.log"  : logFileName 

          Lumberjack.configure(; modes = ["debug", "info", "warn", "error", "crazy"])
          Lumberjack.add_truck(LumberjackTruck(logFileName, "romeo-app"))
          Lumberjack.add_saw(Lumberjack.msec_date_saw)
          Lumberjack.log("debug", "starting main with args")
    end

    parsed_args["debugSX"] != nothing &&   SemXMLSubscreen.setDebugLevels(true,
				parsed_args["debugSX"])
    parsed_args["debugSC"] != nothing &&   SubScreens.setDebugLevels(true,
				parsed_args["debugSC"])
    parsed_args["debugRLib"] != nothing && RomeoLib.setDebugLevels(true,
				parsed_args["debugRLib"])

    realMain(onlyImg, pcamSel=pcamSel,  plotDim=plotDim, xml=xml )    
end

main(ARGS)

restoreErrStream(os)
close(ns)

