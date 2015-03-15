# --line 7349 --  -- from : "BigData.pamphlet"  
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
# --line 7362 --  -- from : "BigData.pamphlet"  
@doc """   Drop repeated signals
     """   ->
function dropequal(a::Signal)
    is_equal = foldl((false, a.value), a) do v0, v1
        (v0[2] == v1, v1)
    end
    dropwhen(lift(first, is_equal), a.value, a)
end
# --line 7374 --  -- from : "BigData.pamphlet"  
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
# --line 7389 --  -- from : "BigData.pamphlet"  
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
# --line 7416 --  -- from : "BigData.pamphlet"  
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
