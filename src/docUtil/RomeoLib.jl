# --line 7364 --  -- from : "BigData.pamphlet"  
# This will move to a library
@doc """   Empty the vector of renderers passed in argument, 
           and delete individually    each element.
     """   ->
function clear!(x::Vector{RenderObject})
    while !isempty(x)
        value = pop!(x)
        delete!(value)
    end
end
# --line 7377 --  -- from : "BigData.pamphlet"  
@doc """   Drop repeated signals
     """   ->
function dropequal(a::Signal)
    is_equal = foldl((false, a.value), a) do v0, v1
        (v0[2] == v1, v1)
    end
    dropwhen(lift(first, is_equal), a.value, a)
end
# --line 7389 --  -- from : "BigData.pamphlet"  
# here we deal with subscreens

@doc """
         Elements of this type define a subscreen's position relative
         to the main screen. E.g. x is the x-offset if the x coordinates
         of the parent screen are the segment [0,1]. These values
         get multiplied by the proper dimension later on.
     """ ->
type SubScreen{T <: Number}
    x::T
    y::T
    w::T
    h::T      
end
# --line 7406 --  -- from : "BigData.pamphlet"  
@doc """ 
         prepare an array of SubScreen{Float}, each with position(x,y) and 
         width(w,h). The arguments are two vectors indicating the relative
         sizes of the rows and of the columns.
     """ ->
function prepSubscreen{T}(colwRel::Vector{T},linehRel::Vector{T})
    sumCol = sum(colwRel)
    sumLine= sum(linehRel)
    ncol =   size(colwRel)[1]
    nlig =   size(linehRel)[1]
    ret = Array(SubScreen{Float64}, nlig,ncol)
    posy = 0
    for i = 1: nlig
      posx = 0
      h =  linehRel[i]/sumLine
      for j = 1: ncol
          w = colwRel[j] / sumCol
          ret[i,j] = SubScreen(float(posx),float(posy),float(w),float(h))
          posx = posx + w
      end
      posy = posy +h
    end
    return ret
end
# --line 7433 --  -- from : "BigData.pamphlet"  
@doc """
         Returns a Rectangle based on:
         Arg. 1:  a SubScreen for proportions 
         Arg. 2:  a vector representing  the (w,h) measures in the x and y 
                  directions.
     """ ->
function RectangleProp(ssc,x)
    Rectangle{Int}( int64(ssc.x*x[1]),  int64(ssc.y*x[2]),
  		    int64(ssc.w*x[1]),  int64(ssc.h*x[2]))
end


# --line 7448 --  -- from : "BigData.pamphlet"  
@doc """  Performs a number of initializations
          It uses the global vizObjArray which is an array of RenderObjects
          that corresponds to the geometric grid built locally in subScreenGeom
     """  -> 
function init_romeo(subScreenGeom, vizObjArray)
    root_area = Romeo.ROOT_SCREEN.area

    # this enables sub-screen dimensions to adapt to  root window changes:
    # a signal is produced with root window's dimensions on display
    screen_height_width = lift(root_area) do area 
        Vector2{Int}(area.w, area.h)
    end

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

# --line 7491 --  -- from : "BigData.pamphlet"  
function interact_loop()
   while Romeo.ROOT_SCREEN.inputs[:open].value
      glEnable(GL_SCISSOR_TEST)
      Romeo.renderloop(Romeo.ROOT_SCREEN)
      sleep(0.01)
   end
   GLFW.Terminate()
end
