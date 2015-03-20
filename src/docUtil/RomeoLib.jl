# --line 7972 --  -- from : "BigData.pamphlet"  
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
# --line 7985 --  -- from : "BigData.pamphlet"  
@doc """   Drop repeated signals
     """   ->
function dropequal(a::Signal)
    is_equal = foldl((false, a.value), a) do v0, v1
        (v0[2] == v1, v1)
    end
    dropwhen(lift(first, is_equal), a.value, a)
end
# --line 7997 --  -- from : "BigData.pamphlet"  
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
# --line 8014 --  -- from : "BigData.pamphlet"  
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
# --line 8041 --  -- from : "BigData.pamphlet"  
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


# --line 8057 --  -- from : "BigData.pamphlet"  
function completeRObj(vol, screen)
      println("in CompleteRObj vol=$vol\n screen=$screen")
      if isa(vol, Dict) && haskey(vol,:render) && isa( vol[:render], NotComplete)
          println("Found incomplete vol=$vol")
          robj=vol[:render].what
          if (isa(vol[:render].func,Void))
             # Need to equip this with a camera
             if ( robj.uniforms[:mvp] == nothing)
                println("Using perspective camera", screen.perspectivecam)
                robj.uniforms[:mvp] = screen.perspectivecam.projectionview
             end    

             vol[:render]=robj
             println("Before pre/post render, vol=")
             println(vol)

             prerender!(robj, glDisable, GL_DEPTH_TEST, glDisable, 
	              GL_CULL_FACE, enabletransparency)
             postrender!(robj, render, robj.vertexarray)

             println("returning vol=")
             println(vol)
             println("++++++    THIS WAS IT +++++\n")
             chkDump(vol) #debug (may be make this parameterized)
             return vol
          else
             Error("Wait a bit.... this is not an incomplete RenderObject ")
          end
      end
      return vol
end



# --line 8094 --  -- from : "BigData.pamphlet"  
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
   # Take into account incomplete RenderObjects (e.g. missing camera)
   for i = 1:size(screenGrid,1), j = 1:size(screenGrid,2)
       scr = screenGrid[i,j]
       vo  = completeRObj( vizObjArray[i,j], scr )
       viz = if ! isa(vo,Dict)
           visualize(vo, screen= scr)
       else
           vf = filter((k,val)-> k != :render, vo)
           vf[:screen] = scr
           visualize(vo[:render]; vf...)
       end

       push!(scr.renderlist, viz)
       chkDump(viz) #debug (may be make this parameterized)

   end
end



# --line 8144 --  -- from : "BigData.pamphlet"  
@doc """  Performs a number of initializations in order to display a
	  single render object in the root window. It is also
          a debugging tool for render objects.
     """  -> 
function init_romeo_single(roFunc)
    root_area = Romeo.ROOT_SCREEN.area
    root_inputs =  Romeo.ROOT_SCREEN.inputs
    root_screen=Romeo.ROOT_SCREEN

    # this enables screen dimensions to adapt to  root window changes:
    # a signal is produced with root window's dimensions on display
    screen_height_width = lift(root_area) do area 
        Vector2{Int}(area.w, area.h)
    end

    screenarea= lift (Romeo.ROOT_SCREEN.area, screen_height_width) do ar,scdim
                RectangleProp(SubScreen(0,0,1,1), scdim) 
    end


    camera_input=copy(root_inputs)
    camera_input[:window_size] = lift(x->Vector4(x.x, x.y, x.w, x.h), screenarea)
    eyepos = Vec3(4)
    centerScene= Vec3(0.0)

    pcam = Romeo.ROOT_SCREEN.perspectivecam
    ocam= Romeo.ROOT_SCREEN.orthographiccam


    screen =Screen(screenarea, root_screen, Screen[], root_screen.inputs, 
                   RenderObject[], 
                    root_screen.hidden, root_screen.hasfocus, pcam, ocam, 
                    root_screen.nativewindow)



    # Visualize a RenderObject on the screen (need an orthographic since
    # it has a projection view)
    vo  = roFunc(screen, pcam )


    println("RenderObject=",vo)
    viz = visualize(vo)   # normally roFunc sets the screen 
    push!( screen.renderlist, viz)
    chkDump(viz)
end

# --line 8290 --  -- from : "BigData.pamphlet"  
function interact_loop()
   while Romeo.ROOT_SCREEN.inputs[:open].value
      glEnable(GL_SCISSOR_TEST)
      Romeo.renderloop(Romeo.ROOT_SCREEN)
      sleep(0.01)
   end
   GLFW.Terminate()
end
# --line 8301 --  -- from : "BigData.pamphlet"  
abstract NotComplete

@doc """
         The type TBCompleted is a wrapper for an item of type T
         which is not deemed complete (ie fit for purpose of a
         T object). 

         The function func if provided should return the
         corresponding T.

        The idea is that the user receiving a TBCompleted (or
        any other NotComplete) should make it complete before proceeding.
        This might mean calling func(what) (if func non Void) or doing
        something to be determined by the user
        
        NB :we are not in the mood of providing Ocaml style streams (although
        this might be a test!)
     """ ->
type TBCompleted{T} <: NotComplete
     what::T
     func::Union(Function,Void)
end
# --line 8327 --  -- from : "BigData.pamphlet"  
# here we have our debug subsection

function unitCube{T<:Number}(zero::T)
    unitcube = Array(T,4,8)
    for i=0:1, j=0:1, k=0:1 
         col = k + 2*j + 4 * i
         unitcube[1,col+1] = i
         unitcube[2,col+1] = j
         unitcube[3,col+1] = k
         unitcube[4,col+1] = 1
    end
    unitcube
end

#code_native( unitCube, (Int32,))

function chkDump(r::RenderObject)
    println("In  chkDump(r::RenderObject)\n\t$r\n")

    cvFl =  x ->convert(Array{Float32,2},x)

    if haskey(r.uniforms, :projectionview)
         projUnitCube = cvFl(r.uniforms[:projectionview].value) * unitCube(1f0)
         println("Has projectionview")
         println("Projected (projectionview) unit cube=\n\t$projUnitCube")

    elseif haskey(r.uniforms, :projection)
         projUnitCube = cvFl(r.uniforms[:projection].value) * unitCube(1f0)
         println("Has projection")
         println("Projected (projection) unit cube=\n\t$projUnitCube")

    else
         println("No projection or projectionview in uniforms")
    end
end
# --line 8365 --  -- from : "BigData.pamphlet"  
function chkDump(d::Dict{Symbol,Any})
    println("In  chkDump(d::Dict{Symbol,Any})\n")
    for (k,v) in d
       if(isa(v,RenderObject))
         print("Dict Key $k\t")
         chkDump(v)
       else
         println("Dict Key $k\t==> $v")         
       end
    end
    
end
