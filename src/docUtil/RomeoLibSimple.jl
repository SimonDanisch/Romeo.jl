# --line 10208 --  -- from : "BigData.pamphlet"  
using  SimpleSubScreens

@doc """  Performs a number of initializations in order to display a
	  single render object in the root window. It is also
          a debugging tool for render objects.
     """  -> 
function init_romeo_single(roFunc;pcamSel=true)
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
    vo  = roFunc(screen, pcamSel? pcam : ocam )

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


# --line 10707 --  -- from : "BigData.pamphlet"  
function interact_loop()
   while Romeo.ROOT_SCREEN.inputs[:open].value
      glEnable(GL_SCISSOR_TEST)
      Romeo.renderloop(Romeo.ROOT_SCREEN)
      sleep(0.01)
   end
   GLFW.Terminate()
end

