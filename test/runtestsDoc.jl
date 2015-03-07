# Added: for documenting, and redirecting streams while debugging
using DocCompat
using ManipStreams

#debug
(os,ns) =  redirectNewFWrite("/tmp/julia.redirected")

using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color

#   From behaviour, we understand that loading GLFW opens the window

@doc """   Empty the vector passed in argument, and delete individually
           each element.
     """   ->
function clear!(x::Vector{RenderObject})
    while !isempty(x)
        value = pop!(x)
        delete!(value)
    end
end

global const gaggaaa = Texture("pic.jpg")

function dropequal(a::Signal)
    is_equal = foldl((false, a.value), a) do v0, v1
        (v0[2] == v1, v1)
    end
    dropwhen(lift(first, is_equal), a.value, a)
end
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
    ==#
    sourcecode_area = lift(Romeo.ROOT_SCREEN.area) do x
    	Rectangle(0, 0, div(x.w, 7)*3, x.h)
    end
    visualize_area = lift(Romeo.ROOT_SCREEN.area) do x
        Rectangle(div(x.w,7)*3, 0, div(x.w, 7)*3, x.h)
    end
    search_area = lift(visualize_area) do x
        Rectangle(x.x, x.y, x.w, div(x.h,10))
    end
    edit_area = lift(Romeo.ROOT_SCREEN.area) do x
    	Rectangle(div(x.w, 7)*6, 0, div(x.w, 7), x.h)
    end


    sourcecode_screen   = Screen(Romeo.ROOT_SCREEN, area=sourcecode_area)
    visualize_screen    = Screen(Romeo.ROOT_SCREEN, area=visualize_area)
    search_screen       = Screen(visualize_screen,  area=search_area)
    edit_screen         = Screen(Romeo.ROOT_SCREEN, area=edit_area)

    
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
        @which output: (interactive)
        visualize(text::AbstractString) at .julia/v0.4/Romeo/src/visualize_interface.jl:22
        visualize(text::String, style::Style=Style(:Default); customization...)
            = visualize(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))
        For all visualize methods, the real effector is
           1 method for generic function "prerender!":
           prerender!(x::GLAbstraction.RenderObject,fs...)
                   at /home/alain/.julia/v0.4/GLAbstraction/src/GLTypes.jl:262
    ==#
    visualize("barplot = Float32[(sin(i/10f0) + cos(j/2f0))/4f0 \n for i=1:10, j=1:10]\n",
              model=source_offset, screen=sourcecode_screen)
    
    const sourcecode  =  visualize("barplot = Float32[(sin(i/10f0) + cos(j/2f0))/4f0 \n for i=1:10, j=1:10]\n", model=source_offset, screen=sourcecode_screen)
    barplot           = Float32[(sin(i/10f0) + cos(j/2f0))/4f0 for i=1:10, j=1:10]
    visualize("barplot\n", model=search_offset, color=rgba(0.9,0,0.2,1), screen=search_screen)
    
    search            =  visualize("barplot\n", model=search_offset, color=rgba(0.9,0,0.2,1), screen=search_screen)

    #== Field editing in sub windows
    ==#
    viz, source_text  = edit(sourcecode[:text], sourcecode)
    viz, search_text  = edit(search[:text], search)

    should_eval = dropequal(lift(Romeo.ROOT_SCREEN.inputs[:buttonspressed]) do keyset
        keyset == IntSet(GLFW.KEY_ENTER, GLFW.KEY_LEFT_CONTROL)
    end)

    soursupdate = lift(source_text, should_eval) do source, seval
        expr = parse(strip(source), raise=false)
        if seval
            if expr.head != :error
                try
                    eval(Main, expr)
                catch e
                    println(e)
                end
            else 
                #println(expr)
            end
        end
        nothing
    end
    a = keepwhen(should_eval, nothing, soursupdate)
    lift(search_text, a) do x, _
        s = symbol(strip(x))
        if isdefined(s)
            value = eval(Main, s)
            if applicable(visualize, value)
                clear!(visualize_screen.renderlist)
                clear!(edit_screen.renderlist)
                push!(MemRefs, value)
                obj     = visualize(value, screen=visualize_screen)
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
    #==
        print ( "In while loop, inputs[:open].value =")
        print (  Romeo.ROOT_SCREEN.inputs)
        print ("\n")

     In while loop, inputs[:open].value = Dict{Symbol,Any}
          (:hasfocus       =>[Reactive.Input{Bool}] true,
           :insidewindow   =>[Reactive.Input{Bool}] false,
           :scroll_x       =>[Reactive.Input{Int64}] 0,
           :windowposition =>[Reactive.Input{ImmutableArrays.Vector2{Int64}}] [1219,297],
           :scroll_y       =>[Reactive.Input{Int64}] 0,
           :framebuffer_size=>[Reactive.Input{ImmutableArrays.Vector2{Int64}}] [1156,535],
           :mousereleased   =>[Reactive.Input{Int64}] 0,
           :buttonreleased  =>[Reactive.Input{Int64}] 341,
           :open=>[Reactive.Input{Bool}] true,
           :mousebuttonspressed=>[Reactive.Input{IntSet}] IntSet([]),
           :mouseposition_glfw_coordinates=>[Reactive.Input{ImmutableArrays.Vector2{Float64}}]
           	[11.6854248046875,197.15802001953125],
           :unicodeinput=>[Reactive.Input{Array{Char,1}}] Char[],
           :mouseposition=>[Reactive.Lift{ImmutableArrays.Vector2{Float64}}]
                      [11.6854248046875,337.84197998046875],
           :mousedown=>[Reactive.Input{Int64}] 0,
           :window_size=>[Reactive.Input{ImmutableArrays.Vector4{Int64}}] [0,0,1156,535],
           :buttondown=>[Reactive.Input{Int64}] 67,
           :buttonspressed=>[Reactive.Input{IntSet}] IntSet([]))
    ==#

    #this deals with double buffering and calls render
    Romeo.renderloop(Romeo.ROOT_SCREEN)

    sleep(0.0001)
end
GLFW.Terminate()

#debug
restoreStream(os)
close(ns)
