# --line 7430 --  -- from : "BigData.pamphlet"  
using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color
using ImmutableArrays
using DocCompat
#  Loading GLFW opens the window

include("RomeoLib.jl")

# --line 7440 --  -- from : "BigData.pamphlet"  
# put cats all over the place!!!
pic = Texture("pic.jpg")
vizObjArray = [ pic  pic ; pic  pic ]
 

# --line 7448 --  -- from : "BigData.pamphlet"  
@doc """  Performs a number of initializations
     """  -> 
function init_romeo()
    root_area = Romeo.ROOT_SCREEN.area

    # this makes sub-screen dimensions adapt to  root window changes
    screen_height_width = lift(root_area) do area 
        Vector2{Int}(area.w, area.h)
    end


    ## Build subscreens
    subScreenGeom = prepSubscreen(Vector([4,1]),Vector([1,4]))
    areaGrid= mapslices(subScreenGeom ,[]) do ssc
          lift (Romeo.ROOT_SCREEN.area,  screen_height_width) do ar,screenDims
                RectangleProp(ssc,screenDims) 
          end
    end

    screenGrid= mapslices(areaGrid, []) do ar
        Screen(Romeo.ROOT_SCREEN, area=ar)
    end

   # put cats all over the place!!!
   #pic = Texture("pic.jpg")
   #mapslices(screenGrid, []) do scr
   #   viz = visualize(pic, screen=scr)
   #   push!(scr.renderlist, viz)
   #end

   # vizObjArray is global

   for i = 1:size(screenGrid,1), j = 1:size(screenGrid,2)
       scr  = screenGrid[i,j]
       viz = visualize(vizObjArray[i,j], screen= scr)
       push!(scr.renderlist, viz)
   end

end

# --line 7492 --  -- from : "BigData.pamphlet"  
ir=init_romeo()
while Romeo.ROOT_SCREEN.inputs[:open].value
    glEnable(GL_SCISSOR_TEST)
    Romeo.renderloop(Romeo.ROOT_SCREEN)
    sleep(0.001)
end
GLFW.Terminate()

