using DocCompat
using Lumberjack
using SimpleSubScreens
#==
    Older version of the screen manager, uses SimpleSubScreens.jl or even
    no subscreen. Kept in case we prefer simpler or no subscreen strategy
    for testing.

    Expect minimal maintenance.
==#

# try to avoid the numerous "deprecated warnings/messages"
using ManipStreams
(os,ns) =  redirectNewFWrite("/tmp/julia.redirected")

using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color
using ImmutableArrays
    #  Loading GLFW opens the window
using Compat

using  XtraRenderObjOGL
include("../src/docUtil/RomeoLib.jl")

function mkSubScrGeom()
    ## Build subscreens, use of screen_height_width permits to
    ## adapt subscreen dimensions to changes in  root window  size
        subScreenGeom = if isless(VERSION, VersionNumber(0,4))
            SimpleSubScreens.prepSubscreen( [4,1]::Vector, [1,4]::Vector )
        else
            SimpleSubScreens.prepSubscreen( Vector([4,1]), Vector([1,4]))
        end
end
# --line 9575 --  -- from : "BigData.pamphlet"  
@doc """
        This function fills the (global) vizObjArray  with functions taking
        arguments:
            screen::Screen 
	    camera::Camera  (GLAbstraction/src/GLCamera.jl)
        and returning the render objects that we wish to show. 

        The corresponding geometry is built in subScreenGeom directly in 
        init_romeo (it contains the (lifted) geometry elements following the
        window changes). As the geometry is built, the functions in vizObjArray
        are called, generating the RenderObjects and filling the renderlist.

        The argument onlyImg is here for debugging , when true we show only
        the same image in all grid positions.
     """  ->
function init_graph_grid(onlyImg::Bool)
   # try with a plot 
   plt = (sc::Screen,cam::GLAbstraction.Camera) -> Float32[ rand(Float32)  
                                                            for i=0:50, j=0:50 ]
   # put the cat all over the place!!!
   pic = (sc::Screen,cam::GLAbstraction.Camera)  -> Texture("pic.jpg")

   # volume : try with a cube (need to figure out how to make this)
   vol = (sc::Screen,cam::GLAbstraction.Camera)-> mkCube(sc,cam)

   # color
   function doColorChooser(sc::Screen,cam::GLAbstraction.Camera)
          TBCompleted (AlphaColorValue(RGB{Float32}(0.8,0.2,0.2), float32(0.5)),
                       nothing, Dict{Symbol,Any}())
   end
   colorBtn = doColorChooser

   vizObjArray = Array(Any,2,2)
            #  elements are functions (see above)
            #  notice that the visualize act is done in init_romeo()

            # rows go from bottom to top, columns from left to right on screen
   vizObjArray[1,1] =  pic
   vizObjArray[1,2] = onlyImg ? pic : vol
   vizObjArray[2,2] = onlyImg ? pic : colorBtn
   vizObjArray[2,1] = onlyImg ? pic : plt

            # init_romeo has the ability to set any attribute in visualize
   return vizObjArray

end  

# --line 9654 --  -- from : "BigData.pamphlet"  
@doc """
       Does the real work, main only deals with the command line options
     """ ->
function realMain(onlyImg::Bool; pcamSel=true)
   init_glutils()

   vizObjArray   = init_graph_grid(onlyImg)
   subScreenGeom = mkSubScrGeom()
   init_romeo( subScreenGeom, vizObjArray; pcamSel = pcamSel )

   interact_loop()
end

@doc """
       Does the real work, simple variant
     """ ->
function realMainSimple(onlyImg::Bool; pcamSel=true)
   init_glutils()   # defined in GLAbstraction/GLInit
                    # in practice loads registerd shaders

   renderObjFn = 
     if onlyImg
       (sc,cam) -> Texture("pic.jpg")
     else
       (sc,cam) -> mkCube(sc,cam) # this is a function object, since
                  # we cannot evaluate before we know the screen 
     		  # and we left camera parametrization in init_romeo_single
     end
   init_romeo_single(renderObjFn; pcamSel=pcamSel )
   interact_loop()
end

# parse arguments, so that we have some flexibility to vary tests on the command line.
using ArgParse
function main(args)
     s = ArgParseSettings(description = "Test of Romeo with grid of objects")   
     @add_arg_table s begin
       "--img","-i"   
               help="Use image instead of other graphics/scenes"
               action = :store_true
       "--cube", "-c"
               help="Test with a single cube in root window/screen"
               action = :store_true 
       "--debugAbs","-d"
               help="show debugging output (in particular from GLRender)"
               arg_type = Int
       "--debugWin","-D"
               help="show debugging output (in particular from GLRender)"
               arg_type = Int
      "--ortho", "-o"       
               help ="Use orthographic camera instead of perspective"
               action = :store_true
       "--log","-l"
               help ="Use lumberjack log"
               arg_type = String

     end    

     s.epilog = """
       GLAbstraction debug levels (ORed bit values)
        Ox01     1 : add traceback for constructors and related
        0x04     4 : print uniforms
        0x08     8 : print vertices
        0x10    16 : reserved for GLTypes.GLVertexArray
        0x10    32 : reserved for postRenderFunctions

       GLWindow debug :
               flagOn : on / off
               *** Level (ORed bit values) :to be allocated ***
     """
    parsed_args = parse_args(s) # the result is a Dict{String,Any}

    onlyImg        = parsed_args["img"]
    cubeSimple     = parsed_args["cube"]
    pcamSel        = !parsed_args["ortho"]

    if parsed_args["log"] != nothing
          logFileName = parsed_args["log"]
          logFileName = length(logFileName) < 5 ? "/tmp/RomeoLumber.log"  : logFileName 

          Lumberjack.configure(; modes = ["debug", "info", "warn", "error", "crazy"])
          Lumberjack.add_truck(LumberjackTruck(logFileName, "romeo-app"))
          Lumberjack.add_saw(Lumberjack.msec_date_saw)
          Lumberjack.log("debug", "starting main with args")
    end

    parsed_args["debugAbs"] != nothing && GLAbstraction.setDebugLevels( true,  
                                                      parsed_args["debugAbs"])
    parsed_args["debugWin"] != nothing && GLWindow.setDebugLevels( true, 
                                                      parsed_args["debug"])

    ### NOW, run the program 
    cubeSimple ?   realMainSimple(onlyImg; pcamSel=pcamSel ) :
                   realMain(onlyImg ; pcamSel=pcamSel)    
end

main(ARGS)

restoreErrStream(os)
close(ns)

