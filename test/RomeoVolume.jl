# --line 8486 --  -- from : "BigData.pamphlet"  
using DocCompat

# try to avoid the numerous "deprecated warnings/messages"
using ManipStreams
(os,ns) =  redirectNewFWrite("/tmp/julia.redirected")

using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color
using ImmutableArrays
    #  Loading GLFW opens the window
using GLPlot      # this will provide some default constructed objets from
                  # GLPlot; unclear whether we want to keep the stuff
                  # global ocamera,pcamera
using Compat
include("../src/docUtil/RomeoLib.jl")


# --line 8505 --  -- from : "BigData.pamphlet"  
function mkSubScrGeom()
    ## Build subscreens, use of screen_height_width permits to
    ## adapt subscreen dimensions to changes in  root window  size
    subScreenGeom = if isless(VERSION, VersionNumber(0,4))
            prepSubscreen( [4,1]::Vector, [1,4]::Vector )
    else
            prepSubscreen( Vector([4,1]), Vector([1,4]))
    end
end

# --line 5498 --  -- from : "BigData.pamphlet"  
# for now, we found a ready made cube
function mkCubeShape()
     vertices, uv, indexes = gencube(1,1,1)
     return ( vertices, uv, indexes)
end
# --line 5506 --  -- from : "BigData.pamphlet"  
# For now this is is inspired by grid.jl
@doc """
      Create a RenderObject containing Cube(s)
      WARNING:in this design we return an incomplete RenderObject, mvp missing!!
""" ->
function mkCube()
	global gridshader

        v,uv,i =mkCubeShape()
        println("In mkCube : ",  typeof(v), "\t", typeof(uv), "\t", typeof(i) )
        println("\tv=$v")
        println("\tuv=$uv")
        println("\ti=$i")

        robj = RenderObject(@compat(Dict(
                        :vertexes                => GLBuffer(v,3),
                        :indexes                  => indexbuffer(i),
                        :fg_color                 => Float32[0.1,.1,.1, 1.0],
                        :bg_color                 => Input(Vec4(0.3, 0.3, 1, 0.5)),
                        # try to do without camera, so that this is an incomplete RenderObject
                        :mvp                        => nothing
                )), gridshader)        

#        prerender!(robj, glDisable, GL_DEPTH_TEST, glDisable, GL_CULL_FACE, enabletransparency)
#        postrender!(robj, render, robj.vertexarray)
        return TBCompleted(robj,nothing)
end


# --line 5538 --  -- from : "BigData.pamphlet"  
function mkCube(screen,camera)
	global gridshader

        v,uv,i =mkCubeShape()
        println("In mkCube(screen,camera) : v::",  typeof(v), 
                                "\tuv::", typeof(uv), "\ti::", typeof(i) )
        println("       type gridshaper=\t", typeof(gridshader))
        println("\tv=$v")
        println("\tuv=$uv")
        println("\ti=$i")

        robj = RenderObject(@compat(Dict(
                 :vertexes                => GLBuffer(v,3),
                 :indexes                 => indexbuffer(i),
                 :fg_color                => Float32[0.1,.1,.1, 1.0],
                 :bg_color                => Input(Vec4(0.3, 0.3, 1, 0.5)),
                 :mvp                     => camera.projectionview
                            
                )), gridshader)        

        prerender!(robj, glDisable, GL_DEPTH_TEST, glDisable, GL_CULL_FACE, enabletransparency)
        postrender!(robj, render, robj.vertexarray)
        return robj
end


function initgrid()  
   sourcedir = "/home/alain/julia.d/v0.4/Romeo/src"
   shaderdir = joinpath(sourcedir, "shader")
   global gridshader 
   gridshader = TemplateProgram( joinpath(shaderdir,"grid.vert"),
		 			  joinpath(shaderdir,"grid.frag"))
   # debug
   println("initgrid, setting gridshader to grid.vert+frag")
   println( gridshader)
   println("Here comes the traceback")
   Base.show_backtrace(STDOUT, backtrace())

end

# adds initgrid on the list of things to be done by init_glutils in GLAbstraction/GLInit
# so this is done while "compiling"
init_after_context_creation(initgrid)

# --line 8524 --  -- from : "BigData.pamphlet"  
@doc """
        This function fills the (global) vizObjArray  with the various
        render objects that we wish to show. 
        The corresponding geometry is built in subScreenGeom directly in 
        init_romeo (it contains the (lifted) geometry elements following the
        window changes).

        The argument onlyImg is here for debugging , when true we show only
        the same image in all grid positions.
     """  ->
function init_graph_grid(onlyImg::Bool)
   vizObjArray = Array(Any,2,2)
            #elements are either Dicts or render??(what type?) 

   # try with a plot 
   plt = Float32[rand(Float32)  for i=0:50, j=0:50]
            # color = rgba(1.0,0.0,0.0,0.4) )
            #  notice that the visualize act is done in init_romeo()

   # put cats all over the place!!!
   pic = Texture("pic.jpg")

   # volume : try with a cube (need to figure out how to make this)
   vol =  mkCube()

            # rows go from bottom to top, columns from left to right on screen
   vizObjArray[1,1] = pic
   vizObjArray[1,2] = onlyImg ? pic :
                                @compat Dict{Symbol,Any}(:render  => vol, 
                                    :color   => rgba(1.0,0.0,0.0,0.4))
   vizObjArray[2,2] = pic
   vizObjArray[2,1] = onlyImg ? pic :
                                @compat Dict{Symbol,Any}(:render  => plt, 
                                    :color   => rgba(1.0,0.0,0.0,0.4))
            # init_romeo has the ability to set any attribute in visualize
   return vizObjArray
end  

# --line 8566 --  -- from : "BigData.pamphlet"  
@doc """
       Does the real work, main only deals with the command line options
     """ ->
function realMain(onlyImg::Bool)
   init_glutils()

   vizObjArray = init_graph_grid(onlyImg)
   subScreenGeom = mkSubScrGeom()
   init_romeo( subScreenGeom, vizObjArray)
   interact_loop()
end


# --line 8582 --  -- from : "BigData.pamphlet"  
@doc """
       Does the real work, simple variant
     """ ->
function realMainSimple(onlyImg::Bool)
   init_glutils()   # defined in GLAbstraction/GLInit
                    # in practice loads registerd shaders

   renderObjFn = 
     if onlyImg
       (sc,cam) -> Texture("pic.jpg")
     else
       (sc,cam) -> mkCube(sc,cam) # this is a function object, since
                                  # we cannot evaluate before we know the screen 
     end
   init_romeo_single(renderObjFn)
   ###
      # Look into the Romeo.ROOT_SCREEN
      println("Romeo.ROOT_SCREEN")
      println(Romeo.ROOT_SCREEN)
      println("+++ This is it !! +++")
   ###
   interact_loop()
end

# --line 8610 --  -- from : "BigData.pamphlet"  
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
       "--debug","-d"
               help="show debugging output (in particular from GLRender)"
               arg_type = Int
     end    

     s.epilog = """
          More explanations to come here
     """
    parsed_args = parse_args(s) # the result is a Dict{String,Any}

    onlyImg        = parsed_args["img"]
    cubeSimple     = parsed_args["cube"]

    if parsed_args["debug"] != nothing
          GLAbstraction.setDebugLevels( true,  parsed_args["debug"])
          GLWindow.setDebugLevels( true,  parsed_args["debug"])
    end

    ### NOW, run the program 
    cubeSimple ?   realMainSimple(onlyImg) : realMain(onlyImg)    
end

main(ARGS)

restoreErrStream(os)
close(ns)

