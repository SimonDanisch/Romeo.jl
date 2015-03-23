# --line 7430 --  -- from : "BigData.pamphlet"  
using DocCompat

using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color
using ImmutableArrays
    #  Loading GLFW opens the window

include("RomeoLib.jl")


# --line 7442 --  -- from : "BigData.pamphlet"  
@doc """  Performs a number of initializations
          It uses the global vizObjArray which is an array of RenderObjects
          that corresponds to the geometric grid built locally in subScreenGeom
     """  -> 
function init_romeo()
    root_area = Romeo.ROOT_SCREEN.area

    # this enables sub-screen dimensions to adapt to  root window changes:
    # a signal is produced with root window's dimensions on display
    screen_height_width = lift(root_area) do area 
        Vector2{Int}(area.w, area.h)
    end


    ## Build subscreens, use of screen_height_width permits to
    ## adapt subscreen dimensions to changes in  root window  size
    subScreenGeom = prepSubscreen(Vector([4,1]),Vector([1,4]))
    areaGrid= mapslices(subScreenGeom ,[]) do ssc
          lift (Romeo.ROOT_SCREEN.area,  screen_height_width) do ar,screenDims
                RectangleProp(ssc,screenDims) 
          end
    end

    # Make subscreens of Screen type, each equipped with renderlist
    # We will then put RenderObject in each of the subscreens
    screenGrid= mapslices(areaGrid, []) do ar
        Screen(Romeo.ROOT_SCREEN, area=ar)
    end


   # vizObjArray is global
   # Equip each subscreen with a RenderObject 
   for i = 1:size(screenGrid,1), j = 1:size(screenGrid,2)
       scr = screenGrid[i,j]
       vo  = vizObjArray[i,j]
       viz = if ! isa(vo,Dict)
           visualize(vo, screen= scr)
       else
           vf = filter((k,val)-> k != :render, vo)
           vf[:screen] = scr
           visualize(vo[:render]; vf...)
       end

       push!(scr.renderlist, viz)
   end

end
# --line 7493 --  -- from : "BigData.pamphlet"  
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
                                Dict{Symbol,Any}(:render  => vol, 
                                    :color   => rgba(1.0,0.0,0.0,0.4))
   vizObjArray[2,2] = pic
   vizObjArray[2,1] = onlyImg ? pic :
                                Dict{Symbol,Any}(:render  => plt, 
                                    :color   => rgba(1.0,0.0,0.0,0.4))
            # init_romeo has the ability to set any attribute in visualize
end  
# --line 7530 --  -- from : "BigData.pamphlet"  
vizObjArray = Array(Any,2,2)
            #elements are either Dicts or render??(what type?) 

@doc """
       Does the real work, main only deals with the command line options
     """ ->
function realMain(onlyImg::Bool)

   init_graph_grid(onlyImg)
   init_romeo()
   while Romeo.ROOT_SCREEN.inputs[:open].value
      glEnable(GL_SCISSOR_TEST)
      Romeo.renderloop(Romeo.ROOT_SCREEN)
      sleep(0.01)
   end
   GLFW.Terminate()
end

# --line 7551 --  -- from : "BigData.pamphlet"  
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
