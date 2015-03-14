using GLFW, GLAbstraction, Reactive, ModernGL, Color,Compat, ImmutableArrays
include("../src/color.jl")
include("../src/types.jl")
include("../src/visualize/text.jl")
include("../src/share/text.jl")
include("../src/visualize/image.jl")
include("../src/visualize_interface.jl")

immutable Screen
    id::Symbol
    area
    parent::Screen
    children::Vector{Screen}
    inputs::Dict{Symbol, Any}
    renderlist::Vector{RenderObject}

    hidden::Signal{Bool}
    hasfocus::Signal{Bool}

    perspectivecam::PerspectiveCamera
    orthographiccam::OrthographicCamera
    nativewindow::GLFW.Window
    counter = 1
    function Screen(
    	area,
	    parent::Screen,
	    children::Vector{Screen},
	    inputs::Dict{Symbol, Any},
	    renderlist::Vector{RenderObject},

	    hidden::Signal{Bool},
	    hasfocus::Signal{Bool},

	    perspectivecam::PerspectiveCamera,
	    orthographiccam::OrthographicCamera,
	    nativewindow::GLFW.Window)
        new(symbol("display"*string(counter+=1)), area, parent, children, inputs, renderlist, hidden, hasfocus, perspectivecam, orthographiccam, nativewindow)
    end

    function Screen(
        area,
        children::Vector{Screen},
        inputs::Dict{Symbol, Any},
        renderlist::Vector{RenderObject},

        hidden::Signal{Bool},
        hasfocus::Signal{Bool},

        perspectivecam::PerspectiveCamera,
        orthographiccam::OrthographicCamera,
        nativewindow::GLFW.Window)
        parent = new()
        new(symbol("display"*string(counter+=1)), area, parent, children, inputs, renderlist, hidden, hasfocus, perspectivecam, orthographiccam, nativewindow)
    end
end

function Screen(
        parent::Screen;
        area 				      = parent.area,
        children::Vector{Screen}  = Screen[],
        inputs::Dict{Symbol, Any} = copy(parent.inputs),
        renderlist::Vector{RenderObject} = RenderObject[],

        hidden::Signal{Bool}   	  = parent.hidden,
        hasfocus::Signal{Bool}    = parent.hasfocus,

        
        nativewindow::GLFW.Window 	   = parent.nativewindow)

	insidescreen = lift(inputs[:mouseposition]) do mpos
		isinside(area.value, mpos...) && !any(children) do screen 
			isinside(screen.area.value, mpos...)
		end
	end

	camera_input = merge(inputs, @compat(Dict(
		:mouseposition 	=> keepwhen(insidescreen, Vector2(0.0), inputs[:mouseposition]), 
		:scroll_x 		=> keepwhen(insidescreen, 0, inputs[:scroll_x]), 
		:scroll_y 		=> keepwhen(insidescreen, 0, inputs[:scroll_y]), 
		:window_size 	=> lift(x->Vector4(x.x, x.y, x.w, x.h), area)
	)))
	ocamera      = OrthographicPixelCamera(camera_input)
	pcamera  	 = PerspectiveCamera(camera_input, Vec3(2), Vec3(0))
    screen = Screen(area, parent, children, inputs, renderlist, hidden, hasfocus, pcamera, ocamera, nativewindow)
	push!(parent.children, screen)
	screen
end
function GLAbstraction.isinside(x::Screen, position::Vector2)
	!any(screen->inside(screen.area.value, position...), x.children) && inside(x.area, position...)
end

function Screen(obj::RenderObject, parent::Screen)

	area 	 = boundingbox2D(obj)
	hidden   = Input(false)
	screen 	 = Screen(parent)
	mouse 	 = filter(inside, Input(Screen), parent.inputs[:mouseposition])

	hasfocus = lift(parent.inputs[:mouseposition], parent.inputs[:mousebuttonpressed], screen.area) do pos, buttons, area
		isinside(area, pos...) && !isempty(bottons)
	end
	buttons  = menubar(screen)
	push!(parent.children, screen)
	push!(screen.renderlist, buttons)
	push!(screen.renderlist, obj)
end

function Screen(style::Style{:Default}, parent=first(SCREEN_STACK))

	hidden   	= Input(true)
	screen 	 	= Screen(parent)
	mouse 	 	= filter(Input(Screen), parent.inputs[:mouseposition]) do screen, mpos
	end
	inputs 		= merge(parent.inputs, @compat(Dict(:mouseposition=>mouse)))
	opxcamera   = OrthographicPixelCamera(inputs)
	pcamera  	= PerspectiveCamera(inputs)
	hasfocus 	= lift(parent.inputs[:mouseposition], parent.inputs[:mousebuttonpressed], screen.area) do pos, buttons, area
		isinside(area, pos...) && !isempty(bottons)
	end
	screen 		= Screen(area, parent, children=Screen[], inputs, renderList, hidden, hasfocus, perspectivecam, orthographiccam)
	buttons     = menubar(screen, style)

	push!(parent.children, screen)
	push!(screen.renderlist, buttons)

end


function GLAbstraction.render(x::Screen)
    glViewport(x.area.value)
    render(x.renderlist)
    render(x.children)
end






GLFW.Init()
GLFW.WindowHint(GLFW.SAMPLES, 4)
w = 1200
h = 1000
window = GLFW.CreateWindow(w, h, "name")
GLFW.MakeContextCurrent(window)
GLFW.ShowWindow(window)
framebuffers 		= Input(Vector2{Int}(w, h))
window_size 		= Input(Vector4{Int}(0, 0, w, h))
inputs =  Dict(
	:insidewindow 					=> Input(false),
	:open 							=> Input(true),
	:hasfocus						=> Input(false),

	:window_size					=> window_size,
	:framebuffer_size 				=> framebuffers,
	:windowposition					=> Input(Vector2(0)),

	:unicodeinput					=> Input(Char[]),

	:buttonspressed					=> Input(IntSet()),
	:buttondown						=> Input(0),
	:buttonreleased					=> Input(0),

	:mousebuttonspressed			=> Input(IntSet()),
	:mousedown						=> Input(0),
	:mousereleased					=> Input(0),

	:mouseposition					=> Input(Vector2(0.0)),
	:mouseposition_glfw_coordinates	=> Input(Vector2(0.0)),

	:scroll_x						=> Input(0),
	:scroll_y						=> Input(0)
)
pcamera  = PerspectiveCamera(inputs, Vec3(2), Vec3(0))
pocamera = OrthographicPixelCamera(inputs)


ROOT_SCREEN = Screen(Input(Rectangle(0,0,1200,1000)), Screen[], inputs, RenderObject[], Input(false), inputs[:hasfocus], pcamera, pocamera, window)


function clear!(x::Vector{RenderObject})
    while !isempty(x)
        value = pop!(x)
        delete!(value)
    end
end
global gaggaaa = Texture("pic.jpg")

visualize_area = lift(ROOT_SCREEN.area) do x
Rectangle(div(x.w,7)*3, 0, div(x.w, 7)*3, x.h)
end
search_area = lift(visualize_area) do x
Rectangle(x.x, x.y, x.w, div(x.h,10))
end
visualize_screen = Screen(ROOT_SCREEN, area=visualize_area)

search_screen 	 = Screen(visualize_screen,  area=search_area)
w_height_search  = lift(search_screen.area) do x
    x.h
end
search_offset = lift(w_height_search) do x
    translationmatrix(Vec3(30,x-30,0))
end

search = visualize(Float32[1f0 for i=1:10, j=1:10], screen=search_screen)
push!(search_screen.renderlist, search)

@async for i = 1:100
	if i == 100
		value = eval(Main, :gaggaaa)
	    clear!(visualize_screen.renderlist)
	    obj     = visualize(value, screen=visualize_screen)
	    push!(visualize_screen.renderlist, obj)
	end
	sleep(0.01)
end



glClearColor(0,0,0,0)
function renderloop(screen)
  
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
	
	yield()
  	render(screen)
  	
	GLFW.SwapBuffers(screen.nativewindow)
	GLFW.PollEvents()
end
while Romeo.ROOT_SCREEN.inputs[:open].value
    renderloop(Romeo.ROOT_SCREEN)
    sleep(0.0001)
end
GLFW.Terminate()