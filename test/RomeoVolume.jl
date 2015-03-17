# --line 7504 --  -- from : "BigData.pamphlet"  
using DocCompat

using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color
using ImmutableArrays
    #  Loading GLFW opens the window
using Compat
include("../src/docUtil/RomeoLib.jl")


# --line 7516 --  -- from : "BigData.pamphlet"  
function mkSubScrGeom()
    ## Build subscreens, use of screen_height_width permits to
    ## adapt subscreen dimensions to changes in  root window  size
    subScreenGeom = if isless(VERSION, VersionNumber(0,4))
            prepSubscreen( [4,1]::Vector, [1,4]::Vector )
    else
            prepSubscreen( Vector([4,1]), Vector([1,4]))
    end
end
# --line 7530 --  -- from : "BigData.pamphlet"  
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

   # volume : try with a cube (need to figure out how to make this)
   vol =  Texture("pic.jpg")
   # put cats all over the place!!!
   pic = Texture("pic.jpg")


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

# --line 7572 --  -- from : "BigData.pamphlet"  
@doc """
       Does the real work, main only deals with the command line options
     """ ->
function realMain(onlyImg::Bool)

   vizObjArray = init_graph_grid(onlyImg)
   subScreenGeom = mkSubScrGeom()
   init_romeo( subScreenGeom, vizObjArray)
   interact_loop()
end

# --line 7586 --  -- from : "BigData.pamphlet"  
# parse arguments, so that we have some flexibility to vary tests on the command line.
using ArgParse

function main(args)
     s = ArgParseSettings(description = "Test of Romeo with grid of objects")   
     @add_arg_table s begin
       "--img","-i"   
               help="Use image instead of other graphics/scenes"
               action = :store_true
     end    

     s.epilog = """
          More explanations to come here
     """
    parsed_args = parse_args(s) # the result is a Dict{String,Any}

    onlyImg     = parsed_args["img"]
    realMain(onlyImg)
end

main(ARGS)
