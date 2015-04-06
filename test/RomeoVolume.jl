# --line 9942 --  -- from : "BigData.pamphlet"  
using DocCompat
using Lumberjack
using TBCompletedM

# try to avoid the numerous "deprecated warnings/messages"
using ManipStreams
(os,ns) =  redirectNewFWrite("/tmp/julia.redirected")

using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color
using ImmutableArrays
    #  Loading GLFW opens the window
using Compat

using  XtraRenderObjOGL
include("../src/docUtil/RomeoLib.jl")

# --line 9962 --  -- from : "BigData.pamphlet"  
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
function init_graph_grid(onlyImg::Bool, plotDim=2)
   # try with a plot
   npts = 50 
   function plotFn2D(i,j)
         x = Float32(i)/Float32(npts)-0.5 
         y = Float32(j)/Float32(npts)-0.5 
         ret = if ( x>=0 ) && ( x>=y)
                   4*x*x+2*y*y
               elseif ( x<0) 
                   2*sin(2.0*3.1416*x)*sin(3.0*3.1416*y)
               else
                   0.0
               end
          ret
   end
   function doPlot2D (sc::Screen,cam::GLAbstraction.Camera)
           TBCompleted ( Float32[ plotFn2D(i,j)  for i=0:npts, j=0:npts ],
                         nothing, Dict{Symbol,Any}(:SetPerspectiveCam => true)
                       )
   end  

   npts3D = 12
   function plotFn3D(i,j,k)
         x = Float32(i)/Float32(npts3D)-0.5 
         y = Float32(j)/Float32(npts3D)-0.5 
         z = Float32(k)/Float32(npts3D)-0.5 

         ret = if ( x>=0 ) && ( x>=y)
                   2*x*x+3*y*y+z*z
               elseif ( x<0) 
                   2*sin(2.0*3.1416*x)*sin(3.0*3.1416*y)
               else
                   9*x*y*z
               end
          ret
   end
   function doPlot3D (sc::Screen,cam::GLAbstraction.Camera)
           dd = Dict{Symbol,Any}(:SetPerspectiveCam => true) 
           TBCompleted ( Float32[ plotFn3D(i,j,k) for i=0:npts3D, 
                                   j=0:npts3D, k=0:npts3D ],
                         nothing, dd)
   end  


   plt = plotDim==2 ? doPlot2D : doPlot3D
   # put the cat all over the place!!!
   pic = (sc::Screen,cam::GLAbstraction.Camera)  -> Texture("pic.jpg")

   # volume : try with a cube (need to figure out how to make this)
   vol = (sc::Screen,cam::GLAbstraction.Camera)-> mkCube(sc,cam)

   # color
   function doColorChooser(sc::Screen,cam::GLAbstraction.Camera)
          TBCompleted (AlphaColorValue(RGB{Float32}(0.8,0.2,0.2), float32(0.5)),
                       nothing, Dict{Symbol,Any}(:doColorChooser=> true))
   end
   colorBtn = doColorChooser

   # edit
   # this is an oversimplification!! (look at exemple!!)
   function doEdit(sc::Screen,cam::GLAbstraction.Camera)
     "barplot = Float32[(sin(i/10f0) + cos(j/2f0))/4f0 \n for i=1:10, j=1:10]\n"
   end

   # subscreen geometry 
   scOuter = prepSubscreen([1.; 4.],[3.; 1.])
   scRight = prepSubscreen([1.; 1.;1.;1.],[1.])
   insertChildren!(scOuter, 2, 2, scRight)

   # compute the geometric rectangles by walking down the geometry
   vizObj =computeRects(GLAbstraction.Rectangle{Float64}(0.,0.,1.,1.), scOuter) 

   #insert the functions that will cause RenderObject to be instantiated
   #and put in the proper render lists
   vizObj[1,1].attrib[RObjFn]         = onlyImg ? pic : doEdit
   vizObj[1,2].attrib[RObjFn]         = onlyImg ? pic : vol
   vizObj[(2,2),(1,1)].attrib[RObjFn] = onlyImg ? pic : colorBtn
   vizObj[(2,2),(2,1)].attrib[RObjFn] = onlyImg ? pic : plt
   vizObj[(2,2),(3,1)].attrib[RObjFn] = onlyImg ? pic : plt
   vizObj[(2,2),(4,1)].attrib[RObjFn] = onlyImg ? pic : plt
   vizObj[2,1].attrib[RObjFn]         = onlyImg ? pic : plt

   # enter rotation parameters for 3 plt, after having required check of feature
   vizObj[(2,2),(2,1)].attrib[ROReqVirtUser] = VFRotateModel| VFTranslateModel
   vizObj[(2,2),(2,1)].attrib[RORot] = (π/2.01,  0.,      0.)

   vizObj[(2,2),(3,1)].attrib[ROReqVirtUser] = VFRotateModel| VFTranslateModel
   vizObj[(2,2),(3,1)].attrib[RORot] = (    0., π/2.01,   0.)

   vizObj[(2,2),(4,1)].attrib[ROReqVirtUser] = VFRotateModel| VFTranslateModel
   vizObj[(2,2),(4,1)].attrib[RORot] = (    0.,   0.,    π/2.01,)


   #vizObj[(2,2),(3,1)].attrib[RODumpMe]  = true

   return vizObj

end  

# --line 10080 --  -- from : "BigData.pamphlet"  
@doc """
       Does the real work, main only deals with the command line options.
       - init_glutils    :initialization functions (see the GL* libraries)
       - init_graph_grid :prepare a description of the subscreens
       - init_romeo      :construct the subscreens, use the description
                          of subscreens to actually build them (calls visualize)
     """ ->
function realMain(onlyImg::Bool;pcamSel=true, plotDim=2)
   init_glutils()

   vizObjSC   = init_graph_grid(onlyImg, plotDim)
   init_romeo( vizObjSC; pcamSel = pcamSel )

   interact_loop()
end

# --line 10100 --  -- from : "BigData.pamphlet"  
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
    pcamSel        = !parsed_args["ortho"]
    plotDim        = (parsed_args["dim"] != nothing) ?  parsed_args["dim"] : 2

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
    realMain(onlyImg; pcamSel=pcamSel, plotDim=plotDim)    
end

main(ARGS)

restoreErrStream(os)
close(ns)

