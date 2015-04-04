# --line 8300 --  -- from : "BigData.pamphlet"  
using SubScreens
using TBCompletedM

@doc """   Empty the vector of renderers passed in argument, 
           and delete individually    each element.
     """   ->
function clear!(x::Vector{RenderObject})
    while !isempty(x)
        value = pop!(x)
        delete!(value)
    end
end
# --line 8966 --  -- from : "BigData.pamphlet"  
using DebugTools
using ROGeomOps     ## geometric OpenGL transformations on RenderObjects


# --line 8973 --  -- from : "BigData.pamphlet"  
@doc """  Performs a number of initializations
          Construct all RenderObjects (suitably parametrized) and inserts them in
          renderlist.

          It uses vizObjArray which is an array of functions building RenderObjects
          that corresponds (cell by cell based on indices) to the geometric grid built
          locally in subScreenGeom

          NOTE: THIS VERSION CORRESPONDS TO NON RECURSIVE=FLAT GRIDDING
                ** MIGHT BE PHASED OUT **
     """  -> 
function init_romeo(subScreenGeom, vizObjArray; pcamSel=true)
    root_area = Romeo.ROOT_SCREEN.area
    global_inputs = Romeo.ROOT_SCREEN.inputs

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

### old##       camera_input=copy(scr.inputs)
### old##       camera_input[:window_size] = lift(x->Vector4(x.x, x.y, x.w, x.h), scr.area)

       # the  selection of signals to drive cameras (in correct subscreen) is from S.Danisch example 
       # (synchronized subscreens)
       #checks if mouse is inside 
       insidescreen = lift(global_inputs[:mouseposition]) do mpos
             isinside(scr.area.value, mpos...) 
       end
       # creates signals for the camera, which are only active if mouse is inside screen
       camera_input = merge(global_inputs, Dict(
         :mouseposition  => keepwhen(insidescreen, Vector2(0.0), global_inputs[:mouseposition]), 
         :scroll_x       => keepwhen(insidescreen, 0, global_inputs[:scroll_x]), 
         :scroll_y       => keepwhen(insidescreen, 0, global_inputs[:scroll_y]), 
       ))
       #this is the reason we have to go through all this. For the correct perspective projection,
       # the camera needs the correct screen rectangle.
       camera_input[:window_size] = lift(x->Vector4(x.x, x.y, x.w, x.h), scr.area)

       eyepos = Vec3(2, 2, 2)
       centerScene= Vec3(0.0)

       pcam = PerspectiveCamera(camera_input,eyepos ,  centerScene)
       ocam=  OrthographicCamera(camera_input)
       camera = pcamSel ? pcam : ocam

       # Build the RenderObjects by calling the supplied function
       vo  = vizObjArray[i,j]( scr, camera )

       # The game here: thy shall not call visualize with a RenderObject
       # ( May be this can be simplified if  my proposed patch in Romeo/src/visualize_interface.jl
       # gets accepted)

       # passing screen= parameter to visualize inspired from test/simple_display_grid.jl
       viz = if ! isa(vo,Dict)
               visualize(vo, screen=scr)
           else
              # do not visualize RenderObjects!
              if ! (   isa(vo[:render],RenderObject) 
                    || isa(vo[:render],(RenderObject...)))
                 visualize(vo, screen=scr)
              else
                 vo
              end
       end

       #chkDump(viz,true) #debug (may be make this parameterized)

       if isa(viz,(RenderObject...))
            for v in viz
                push!(scr.renderlist, v)
            end
       else
            push!(scr.renderlist, viz)
       end

   end
end

# --line 9074 --  -- from : "BigData.pamphlet"  
@doc """  Inner function for init_romeo
""" ->
function equipSubsScreenLeaf(sscLeaf::SubScreen)
       scr = sccLeaf

       # the  selection of signals to drive cameras (in correct subscreen) is from S.Danisch example 
       # (synchronized subscreens)
       #checks if mouse is inside 
       insidescreen = lift(global_inputs[:mouseposition]) do mpos
             isinside(scr.area.value, mpos...) 
       end
       # creates signals for the camera, which are only active if mouse is 
       # inside screen
       camera_input = merge(global_inputs, Dict(
         :mouseposition  => keepwhen(insidescreen, Vector2(0.0), global_inputs[:mouseposition]), 
         :scroll_x       => keepwhen(insidescreen, 0, global_inputs[:scroll_x]), 
         :scroll_y       => keepwhen(insidescreen, 0, global_inputs[:scroll_y]), 
       ))
       # this is the reason we have to go through all this. For the correct
       # perspective projection,
       # the camera needs the correct screen rectangle.
       camera_input[:window_size] = lift(x->Vector4(x.x, x.y, x.w, x.h), scr.area)

       eyepos = Vec3(2, 2, 2)
       centerScene= Vec3(0.0)

       pcam = PerspectiveCamera(camera_input,eyepos ,  centerScene)
       ocam=  OrthographicCamera(camera_input)
       camera = pcamSel ? pcam : ocam

       # Build the RenderObjects by calling the supplied function
       vo  = vizObjTree[i,j]( scr, camera )

       # The game here: thy shall not call visualize with a RenderObject
       # ( May be this can be simplified if  my proposed patch in
       #  Romeo/src/visualize_interface.jl
       # gets accepted)

       # passing screen= parameter to visualize inspired from 
       # test/simple_display_grid.jl
       viz = if ! isa(vo,Dict)
               visualize(vo, screen=scr)
           else
              # do not visualize RenderObjects!
              if ! (   isa(vo[:render],RenderObject) 
                    || isa(vo[:render],(RenderObject...)))
                 visualize(vo, screen=scr)
              else
                 vo
              end
       end

       #chkDump(viz,true) #debug (may be make this parameterized)

       if isa(viz,(RenderObject...))
            for v in viz
                push!(scr.renderlist, v)
            end
       else
            push!(scr.renderlist, viz)
       end

   end # function equipSubsScreenLeaf


# --line 9141 --  -- from : "BigData.pamphlet"  
@doc """  Performs a number of initializations
          Construct all RenderObjects (suitably parametrized) and inserts them in
          renderlist.
          
          The first argument is a fully a SubScreen (tree, with Rectangles 
          expanded/localized via computeRects  ). The attrib dictionnary is exploited 
          to set up the subscreens; all new objects are referenced via the SubScreen
          tree attrib dictionnaries.

          NOTE: THIS VERSION CORRESPONDS RECURSIVE GRIDDING
                ** IN DEVELOPMENT**
     """  -> 
function init_romeo( vObjT::SubScreen; pcamSel=true)
    root_area = Romeo.ROOT_SCREEN.area
    global_inputs = Romeo.ROOT_SCREEN.inputs

    # this enables sub-screen dimensions to adapt to  root window changes:
    # a signal is produced with root window's dimensions on display
    screen_height_width = lift(root_area) do area 
        Vector2{Int}(area.w, area.h)
    end


# --line 9166 --  -- from : "BigData.pamphlet"  
    # set the subscreens areas as signals focused on subscreen rectangles
    fnWalk1 = function(ssc,indx,misc,info)
           info[:isDecomposed] && return
           ssc.attrib[sigArea ] = 
              lift (Romeo.ROOT_SCREEN.area,  screen_height_width) do ar,screenDims
                       RectangleProp(ssc,screenDims) 
                    end   
           println("In fnWalk1 at$indx: sigArea=", value(ssc.attrib[sigArea ]))
    end
    treeWalk!(vObjT,  fnWalk1)

# --line 9179 --  -- from : "BigData.pamphlet"  
    # Make subscreens of Screen type, each equipped with renderlist
    # We will then put RenderObject in each of the subscreens

    fnWalk2 = function(ssc,indx,misc,info)
         info[:isDecomposed] && return
         ssc.attrib[sigScreen ] =   Screen(Romeo.ROOT_SCREEN, area= ssc.attrib[sigArea ])
    end
    treeWalk!(vObjT,  fnWalk2)


# --line 9191 --  -- from : "BigData.pamphlet"  
   # Equip each subscreen with a RenderObject 

    fnWalk3 = function(ssc, indx, misc, info)
       info[:isDecomposed] && return
       haskey(ssc.attrib,RObjFn )  || return

       scr = ssc.attrib[sigScreen ]
       # the  selection of signals to drive cameras (in correct subscreen) is from 
       # S.Danisch example  (synchronized subscreens)

       #checks if mouse is inside 
       insidescreen = lift(global_inputs[:mouseposition]) do mpos
             isinside(scr.area.value, mpos...) 
       end
       # creates signals for the camera, which are only active if mouse is inside screen
       camera_input = merge(global_inputs, Dict(
         :mouseposition  => keepwhen(insidescreen, Vector2(0.0), global_inputs[:mouseposition]), 
         :scroll_x       => keepwhen(insidescreen, 0, global_inputs[:scroll_x]), 
         :scroll_y       => keepwhen(insidescreen, 0, global_inputs[:scroll_y]), 
       ))
       #this is the reason we have to go through all this. For the correct perspective projection,
       # the camera needs the correct screen rectangle.
       camera_input[:window_size] = lift(x->Vector4(x.x, x.y, x.w, x.h), scr.area)

       eyepos = Vec3(2, 2, 2)
       centerScene= Vec3(0.0)

       pcam = PerspectiveCamera(camera_input,eyepos ,  centerScene)
       ocam=  OrthographicCamera(camera_input)
       camera = pcamSel ? pcam : ocam

       # Build the RenderObjects by calling the supplied function
       vo  = ssc.attrib[ RObjFn ]( scr, camera )



# --line 9229 --  -- from : "BigData.pamphlet"  
       # The game here: thy shall not call visualize with a RenderObject
       # ( May be this can be simplified if  my proposed patch in 
       # Romeo/src/visualize_interface.jl gets accepted)

       #screen= parameter to visualize inspired from test/simple_display_grid.jl
       viz =  if isa( vo, NotComplete)
		#good enough for now, will need improvement
                visualize(vo.what)      
           elseif ! isa(vo,Dict)
               visualize(vo, screen=scr)
           else
              # do not visualize RenderObjects!
              if ! (   isa(vo[:render],RenderObject) 
                    || isa(vo[:render],(RenderObject...)))
                 visualize(vo, screen=scr)
              else
                 vo
              end
       end


# --line 9252 --  -- from : "BigData.pamphlet"  
       # Does the user request virtual functions (we need to verify availability or diagnose)
       marker  = haskey(ssc.attrib,ROReqVirtUser) ? ssc.attrib[ROReqVirtUser] : 0
       # Check availability, this will use an external function (in ad hoc module!)
       #TBD!!!
       if  marker  != 0
            if isa(viz,RenderObject) && haskey(viz.manipVirtuals, ROReqVirtUser)
               println("Need to check avail of $marker in",
                        viz.manipVirtuals[ROReqVirtUser]  )
            else
               warn("Cannot check availability of feature $marker in $viz")
            end
       end

# --line 9267 --  -- from : "BigData.pamphlet"  
       # this way the user can request a dump 
       if haskey(ssc.attrib,RODumpMe)
          println("Dump for object viz of type = ",typeof(viz),"")
          function dumpIntern(viz)
              for k in sort(collect(keys( viz.uniforms)))
                 println("RODumpMe\tkey=$k")
	      end
          end
          if isa(viz,(RenderObject...))
             for v in viz
              dumpIntern(v)                 
             end
          else
              dumpIntern(viz)
          end
       end

# --line 9286 --  -- from : "BigData.pamphlet"  
       # stick all this in a different place (may be the module about virtualFns)
       if haskey(ssc.attrib,RORot) 
           println("Please rotate by (angles)", (ssc.attrib[RORot]))
           #chkDump(viz,true) #debug (may be make this parameterized)
           angles= ssc.attrib[RORot]
           rotmat = rotationmatrix_x(Float32(angles[1]))
           println( "typeof(viz)=" ,typeof(viz))

           ### 2 cases (at least): Tuple or not Tuple
           if isa(viz, (Any...))
             for v in viz
                rotateInner(v,rotmat)
             end
	   else  # if isa..
             rotateInner(viz,rotmat)
           end  # if isa..
       end

# --line 9306 --  -- from : "BigData.pamphlet"  
       if isa(viz,(RenderObject...))
            for v in viz
                push!(scr.renderlist, v)
            end
       elseif  isa(viz,(Any...))  
          # here deal with the case of color
          # where a pair (GLAbstraction.RenderObject,
          #               Reactive.Lift{ImmutableArrays.Vector4{Float32}})
            for v in viz
                if   isa(v,RenderObject)  push!(scr.renderlist, v)
                     # discard the Lift.... ? Good or Bad??

                     # Here  we set an attribute (we could use a signal)
                     #chkDump(v,true)
                     v.uniforms[:swatchsize]=Input(4.0f0)
                end
            end
       else
            push!(scr.renderlist, viz)
       end

    end   # function  fnWalk3

# --line 9331 --  -- from : "BigData.pamphlet"  
    treeWalk!(vObjT,  fnWalk3)

end



# --line 9341 --  -- from : "BigData.pamphlet"  
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

# --line 9643 --  -- from : "BigData.pamphlet"  
function interact_loop()
   while Romeo.ROOT_SCREEN.inputs[:open].value
      glEnable(GL_SCISSOR_TEST)
      Romeo.renderloop(Romeo.ROOT_SCREEN)
      sleep(0.01)
   end
   GLFW.Terminate()
end
