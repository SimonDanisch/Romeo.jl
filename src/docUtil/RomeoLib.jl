# --line 8268 --  -- from : "BigData.pamphlet"  
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
# --line 8281 --  -- from : "BigData.pamphlet"  
@doc """   Drop repeated signals
     """   ->
function dropequal(a::Signal)
    is_equal = foldl((false, a.value), a) do v0, v1
        (v0[2] == v1, v1)
    end
    dropwhen(lift(first, is_equal), a.value, a)
end
# --line 8293 --  -- from : "BigData.pamphlet"  
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
# --line 8310 --  -- from : "BigData.pamphlet"  
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
# --line 8337 --  -- from : "BigData.pamphlet"  
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



# --line 8418 --  -- from : "BigData.pamphlet"  
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

       camera_input=copy(scr.inputs)
       camera_input[:window_size] = lift(x->Vector4(x.x, x.y, x.w, x.h), scr.area)

       eyepos = Vec3(2, 2, 2)
       centerScene= Vec3(0.0)

       pcam = PerspectiveCamera(camera_input,eyepos ,  centerScene)
       ocam=  OrthographicCamera(camera_input)
       camera = pcam

       # func = vizObjArray[i,j]
       vo  = vizObjArray[i,j]( scr, camera )
       viz = if ! isa(vo,Dict)
               visualize(vo)
           else
              # do not visualize RenderObjects!
              if ! (   isa(vo[:render],RenderObject) 
                    || isa(vo[:render],(RenderObject...)))
                 visualize(vo)
              else
                 vo
              end
       end

       chkDump(viz,true) #debug (may be make this parameterized)

       if isa(viz,(RenderObject...))
            for v in viz
                push!(scr.renderlist, v)
            end
       else
            push!(scr.renderlist, viz)
       end

   end
end



# --line 8492 --  -- from : "BigData.pamphlet"  
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
    eyepos = Vec3(2, 2, 2)
    centerScene= Vec3(0.0)

    pcam = PerspectiveCamera(camera_input,eyepos ,  centerScene)
    ocam=  OrthographicCamera(camera_input)

    screen =Screen(screenarea, root_screen, Screen[], root_screen.inputs, 
                   RenderObject[], 
                    root_screen.hidden, root_screen.hasfocus, pcam, ocam, 
                    root_screen.nativewindow)

    # Visualize a RenderObject on the screen
    vo  = roFunc(screen, pcam )

    # roFunc may return single objects or Tuples of such
    function registerRo (viz::RenderObject)
        #in this case calling visualize result in an error (stringification)
        push!( screen.renderlist, viz)
        push!( root_screen.renderlist, viz)
    end
    function registerRo (viz::Tuple)
       for v in viz
           registerRo (v)
       end
    end

    registerRo (vo)

    #println("screen=$screen\nEnd of screen\n\tshould be child of ROOT_SCREEN")
    #println("root_screen=$root_screen\nEnd of root screen\n")
    
end

# --line 8646 --  -- from : "BigData.pamphlet"  
function interact_loop()
   while Romeo.ROOT_SCREEN.inputs[:open].value
      glEnable(GL_SCISSOR_TEST)
      Romeo.renderloop(Romeo.ROOT_SCREEN)
      sleep(0.01)
   end
   GLFW.Terminate()
end
# --line 8707 --  -- from : "BigData.pamphlet"  
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
function chkDump(tup::(RenderObject...),more::Bool=false)
     for t in tup
         chkDump(t,more)
     end
end

function chkDump(r::RenderObject,more::Bool=false)
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
    if more
      println("\t extended chkDump")
      for kv in  r.uniforms
          k = kv[1]
          v = kv[2]
          println("uniforms[$k]=\t$v")
      end
      println("\t Vertex Array", r.vertexarray)
    end

    println("+++  End chkDump output  +++\n")
end
# --line 8761 --  -- from : "BigData.pamphlet"  
function chkDump(d::Dict{Symbol,Any},more::Bool=false)
    println("In  chkDump(d::Dict{Symbol,Any})\n")
    for (k,v) in d
       if(isa(v,RenderObject))
         print("Dict Key $k\t")
         chkDump(v,more)
       else
         println("Dict Key $k\t==> $v")         
       end
    end
    
end
