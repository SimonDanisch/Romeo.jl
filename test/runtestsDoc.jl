# Added: for documenting, and redirecting streams while debugging
using DocCompat
using ManipStreams

#debug
(os,ns) =  redirectNewFWrite("/tmp/julia.redirected")

using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color

#   From behaviour, we understand that loading GLFW opens the window

@doc """   Empty the vector passed in argument, and delete individually
           each element. (probably want to ensure the action in destructors
           is performed)
     """   ->
function clear!(x::Vector{RenderObject})
    while !isempty(x)
        value = pop!(x)
        delete!(value)
    end
end

@doc """
         reduce signal to actual variations by dropping events without value variation
         ... (no digital glitches though, only repeated stuff).
     """ ->
function dropequal(a::Signal)
    is_equal = foldl((false, a.value), a)  do v0, v1
                         (v0[2] == v1, v1)
                      end
    dropwhen(lift(first, is_equal), a.value, a)
end


@doc """ Convenience function, ensures that we can force conversion of coordinates
         to Float32.
     """ ->
function RectangleC{T1<:Number, T2<:Number, T3<:Number, T4<:Number }(x::T1,y::T2,w::T3,h::T4)
         xx=convert(Float32,x)
         yy=convert(Float32,y)
         ww=convert(Float32,w)
         hh=convert(Float32,h)
         Rectangle(xx,yy,ww,hh)
     end

@doc """ Convenience function, ensures that we can force conversion of coordinates
         to Int64. We do this in view of the declaration(s) for  OrthographicCamera
	 (excerpt):

         OrthographicCamera{T}(window_size::Signal{Vector4{Int64}},
                              view::Signal{Matrix4x4{T}},
                              projection::Signal{Matrix4x4{T}},
                              projectionview::Signal{Matrix4x4{T}})
     """ ->
function RectangleI{T1<:Number, T2<:Number, T3<:Number, T4<:Number }(x::T1,y::T2,w::T3,h::T4)
             xx=int64(x)  # we use int64 to truncate a floating point if needed
             yy=int64(y)  # whereas convert would give InexactErrors for non integer values
             ww=int64(w)
             hh=int64(h)
             Rectangle(xx,yy,ww,hh)
     end


@doc """ Convenience function, ensures that we do not have typing
         problems when entering Rectangles
     """ ->
     function GLAbstraction.Rectangle{T<:Number}(x::T,y::T,w::T,h::T)
          RectangleC(x,y,w,h)
     end

global const gaggaaa = Texture("pic.jpg")
global MemRefs = Any[]

@doc """  Performs a number of initializations to set up the romeo
	  frames and related signals.

          Areas: sourcecode_area
		 visualize_area
		 search_area
		 edit_area

	  Screens:  sourcecode_screen
		    visualize_screen
		    search_screen
		    edit_screen
                    These are defined in .julia/v0.3/GLWindow/src/reactglfw.jl
                    List of exposed signals https://github.com/JuliaGL/GLWindow.jl


	          names(some_screen)
			11-element Array{Symbol,1}:
			 :id          ::  Symbol   
			 :area        ::  Rectangle        
			 :parent      ::  Screen
			 :children    ::  Array{Screen,1}  
			 :inputs      ::  Dict{Symbol,Any}  
			 :renderlist  ::  Array{RenderObject,1} 
			 :hidden         :: Input{Bool}
			 :hasfocus       :: Input{Bool}
			 :perspectivecam    :: PerspectiveCamera{Float32}
			 :orthographiccam   :: OrthographicCamera{Float32}
			 :nativewindow   :: Window(Romeo)  -> ref (here points to ROOT_SCREEN)


          Other Inputs : searchinput

          Visualize interfaces: (see Romeo/src/visualize_interface.jl)
                   In summary, for all visualize methods, the real effector is
		   the generic function "prerender!":
           		prerender!(x::GLAbstraction.RenderObject,fs...)
                   	at /home/alain/.julia/v0.4/GLAbstraction/src/GLTypes.jl:262

To be continued...
     """  -> 
function init_romeo()
    #==   Define screen areas (can we color code the background for debug?
          What if these were viewports ie: map the said viewport on the screen
    ==#
    sourcecode_area = lift(Romeo.ROOT_SCREEN.area) do x
    	RectangleI(0.0, 0.0, x.w*2.5, x.h*2)
    end
    visualize_area = lift(Romeo.ROOT_SCREEN.area) do x
        RectangleI(x.w*0.4, 0.0, x.w*2.5, x.h*2)
    end
    search_area = lift(visualize_area) do x
        RectangleI(x.x, x.y, x.w*2, x.h*5)
    end
    edit_area = lift(Romeo.ROOT_SCREEN.area) do x
    	RectangleI(x.w*0.6, 0.0, x.w*2, x.h*2)
    end
    plot_area = lift(Romeo.ROOT_SCREEN.area) do x
    	RectangleI(x.w*0.8, 0.0, x.w*2, x.h*2)
    end
    img_area = lift(Romeo.ROOT_SCREEN.area) do x
    	RectangleI(x.w*10, x.h*10, x.w*5, x.h*5)
    end


    sourcecode_screen   = Screen(Romeo.ROOT_SCREEN, area=sourcecode_area)
    visualize_screen    = Screen(Romeo.ROOT_SCREEN, area=visualize_area)
    search_screen       = Screen(visualize_screen,  area=search_area)
    edit_screen         = Screen(Romeo.ROOT_SCREEN, area=edit_area)
    plot_screen         = Screen(Romeo.ROOT_SCREEN, area=plot_area)
    img_screen          = Screen(Romeo.ROOT_SCREEN, area=img_area)

    
    w_height = lift(Romeo.ROOT_SCREEN.area) do x
    	x.h
    end
    source_offset = lift(w_height) do x
        translationmatrix(Vec3(30,x-30,0))
    end
    w_height_search = lift(search_screen.area) do x
        x.h
    end
    search_offset = lift(w_height_search) do x
        translationmatrix(Vec3(30,x-30,0))
    end

    searchinput = Input("barplot")

    #== Assess the method visualize which is used
        For all visualize methods, the real effector is
           prerender!(x::GLAbstraction.RenderObject,fs...)
                   at /home/alain/.julia/v0.4/GLAbstraction/src/GLTypes.jl:262
    ==#

    visualize("barplot = Float32[(sin(i/10f0) + cos(j/2f0))/4f0 \n for i=1:5, j=1:15]\n",
              model=source_offset, screen=sourcecode_screen,
              backgroundcolor=rgba(0.5,0.0,0.0,0.1)) # Not seen
    
    const sourcecode  =  visualize("barplot = Float32[(sin(i/10f0) + cos(j/2f0))/4f0 \n for i=1:10, j=1:10]\n",
                                   model=source_offset,
                                   screen=sourcecode_screen,
                                   backgroundcolor=rgba(0.5,0.2,0.2,1.0)) # Pink Seen

    # create barplot in the current local context, eval symbolically in the visualize
    # edit screen (therefore test access to variables in local context)
    barplot           = Float32[(sin(i/10f0) + cos(j/2f0))/4f0 for i=1:20, j=1:20]
    visualize("barplot\n", model=search_offset, color=rgba(1.0,0.0,0.0,1),
              screen=search_screen,
               backgroundcolor=rgba(0.2,1,0.2,1)) #OK Green not seen
    
    search            =  visualize("barplot\n", model=search_offset, color=rgba(0.9,0,0.2,1),
                                   screen=search_screen,
                                   backgroundcolor=rgba(0.0,0.0,1,1)) # HUM  BLUE

    #== Add a screen, from example testest.jl
        This kind of works (surface is shown), but we have NO mouse effects;
        this does not perturb editing below.
        => Probably lost signals expected by this widget
    ==#
    obj = visualize(Float32[rand(Float32)  for i=0:50, j=0:50],
                    color = rgba(1.0,0.0,0.0,0.4),
                    screen=plot_screen)
    push!(Romeo.ROOT_SCREEN.renderlist, obj) 

               
    #   Show the cat (gaga)           
    obj1 = visualize( gaggaaa , screen=img_screen)
    push!(Romeo.ROOT_SCREEN.renderlist, obj1)


               
    #== Field editing in sub windows
    ==#
    viz, source_text  = edit(sourcecode[:text], sourcecode)
    viz, search_text  = edit(search[:text], search)


    #==  Processing of events/signals
    ==#
    should_eval = dropequal(lift(Romeo.ROOT_SCREEN.inputs[:buttonspressed]) do keyset
        keyset == IntSet(GLFW.KEY_ENTER, GLFW.KEY_LEFT_CONTROL)
    end)
    # should_eval selects  new buttonspressed events, marking series of CTL-ENTER events

    # handle parse requests (CTL-ENTER)
    # following code permits evaluation 
    soursupdate = lift(source_text, should_eval) do source, seval
        if seval
            #  CTL-ENTER: go parse (otherwise simply text editing, enter means new line)
            expr = parse(strip(source), raise=false)
            if expr.head != :error
                try
                    eval(Main, expr)
                    println("Eval successful")
                catch e
                    println("Error in $source\n\tparsed to: expr")
                    println(e)
                end
            else
                println("Parsed head shows error,\n\tsource=$source")
            end
        end
        nothing
    end

    #  select  CTL-ENTER events
    #  why is this different from executing in the first clause of the "if eval" above?
    a = keepwhen(should_eval, nothing, soursupdate)
               
    lift(search_text, a) do x, _
        println("In handler after selection x=$x")
        s = symbol(strip(x))
        if isdefined(s)
            value = eval(Main, s)
            if applicable(visualize, value)
                println("Performing visualize actions in visualize and edit screens")
                clear!(visualize_screen.renderlist)
                clear!(edit_screen.renderlist)
                push!(MemRefs, value)
                obj     = visualize(value, screen=visualize_screen)
#==
         Here, when errors are done internally, and the catch clause uses
         println, we endup in recursive attempts to call push! (not reproduced
         in a simple context using Reactive


 in push! at /home/alain/.julia/v0.3/Reactive/src/Reactive.jl:216
 in update at /home/alain/.julia/v0.3/Reactive/src/timing.jl:11
                          ... deleted entries ---
 in push! at /home/alain/.julia/v0.3/Reactive/src/Reactive.jl:245
 in key_pressed at /home/alain/.julia/v0.3/GLWindow/src/reactglfw.jl:232                                                                
                                                                
 ERROR: push! called when another signal is still updating.

                try
                     objedit = edit(obj,        screen=edit_screen)
                catch e
                    println("Error in edit(obj,screen=edit_scren)")
                    println(e)
                    println("obj=$obj") apparently this causes a loop
                    catch_backtrace()
                    println("*****")
                    backtrace()
                    rethrow()
                    return nothing
                end
==#
                objedit = edit(obj,        screen=edit_screen)
                push!(visualize_screen.renderlist, obj)
                append!(edit_screen.renderlist, objedit)
            end
        end
        nothing
    end

    push!(sourcecode_screen.renderlist, sourcecode)
    push!(search_screen.renderlist, search)
    glClearColor(0,0,0,0)
end

#==
    This prepares the context, which has been passed to the global
    environment via visualize calls, ending up in prerender! in
    GLAbstraction.
==#
init_romeo()

#==
    This is the event loop which uses the following
        function renderloop(ROOT_SCREEN)  defined at: ./display/renderloop.jl
        global ROOT_SCREEN                defined at: ./display/renderloop.jl
==#    
while Romeo.ROOT_SCREEN.inputs[:open].value

    #this deals with double buffering and calls render
    Romeo.renderloop(Romeo.ROOT_SCREEN)

    sleep(0.01)
end
GLFW.Terminate()

#debug
restoreErrStream(os)
close(ns)


#==
    Current issues: (3/13/2015)
       1) positionning on the Window of Screen areas defined with rectangles
          How should we initialize areas (sourcecode_area and the others)
          To begin with: a) ensure the mouse actions for moving a plot is on same area
          as the graph.
                         b) understand how the frustum parameters are set and initialized
              
       2) effect of lift operation, seems that the signals available on ROOT_SCREEN are
          made available for events on the smaller area. Do we have focusing in 
          correspondance with the bounding box of area? 
       4) use of signals / mouse actions to orient the drawing in plot_screen (seems to work,
          if mouse on right of screen)
       5) run time compile error diagnostics I had circumvent (related to typing of QQUAD)
==#
