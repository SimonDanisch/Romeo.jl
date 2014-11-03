using Romeo, GLFW, GLAbstraction, Reactive, ModernGL

immutable Screen2{Style}
    id::Symbol
    area::Signal{Rectangle}
    parent::Screen
    children::Dict{Symbol, Screen}
    inputs::Dict{Symbol, Any}
    renderlist::Vector{RenderObject}

    hidden::Signal{Bool}
    hasfocus::Signal{Bool}

    perspectivecam::PerspectiveCamera
    orthographiccam::OrthographicCamera
    counter = 1
    function Screen2(
    	area::Signal{Rectangle},
	    parent::Screen,
	    children::Dict{Symbol, Screen},
	    inputs::Dict{Symbol, Any},
	    renderlist::Vector{RenderObject},

	    hidden::Signal{Bool},
	    hasfocus::Signal{Bool},

	    perspectivecam::PerspectiveCamera,
	    orthographiccam::OrthographicCamera)

        new(symbol("display"*string(counter+=1)), area, parent, children, inputs, renderList, hidden, hasfocus, perspectivecam, orthographiccam)
    end
    function Screen2(id::Symbol,
                    parent::Screen,
                    children::Vector{Screen},
                    inputs::Dict{Symbol, Any},
                    renderList::Vector{Any})
        new(id::Symbol, parent, children, inputs, renderList)
    end
end


function GLAbstraction.render(x::Screen2)
    glViewport(x.area)
    render(x.renderlist)
    render(x.children)
end

function inside(x::Screen, position::Vector2)
	!any(x->inside(x, position), x.children) && inside(x.area)
end

function Screen(obj::RenderObject, parent::Screen2)

	area 	 = boundingbox2D(obj)
	hidden   = Input(false)
	screen 	 = Screen(parent)
	mouse 	 = filter(inside, Input(Screen), parent.inputs[:mouseposition])

	hasfocus = lift(parent.inputs[:mouseposition], parent.inputs[:mousebuttonpressed], screen.area) do pos, buttons, area
		isinside(pos, area) && !isempty(bottons)
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
	inputs 		= merge(parent.inputs, Dict(:mouseposition=>mouse))
	opxcamera   = OrthographicPixelCamera(inputs)
	pcamera  	= PerspectiveCamera(inputs)
	hasfocus 	= lift(parent.inputs[:mouseposition], parent.inputs[:mousebuttonpressed], screen.area) do pos, buttons, area
		isinside(pos, area) && !isempty(bottons)
	end
	screen 		= Screen(area, parent, children=Screen[], inputs, renderList, hidden, hasfocus, perspectivecam, orthographiccam)
	buttons  = menubar(screen, style)
	push!(parent.children, screen)
	push!(screen.renderlist, buttons)

end


N       = 128
volume  = Float32[sin(x / 12f0)+sin(y / 12f0)+sin(z / 12f0) for x=1:N, y=1:N, z=1:N]
max     = maximum(volume)
min     = minimum(volume)
volume  = (volume .- min) ./ (max .- min)

#push!(Romeo.RENDER_LIST, visualize(volume))
#push!(Romeo.RENDER_LIST, visualize(readall(open("../src/Romeo.jl"))))
#push!(Romeo.RENDER_LIST, visualize(Texture(joinpath(homedir(),"Desktop", "random imgs", "jannis.jpg"))))
inputs = copy(Romeo.window.inputs)
camera = PerspectiveCamera(inputs, Vec3(2), Vec3(0))

push!(Romeo.RENDER_LIST, visualize(Float32[0f0 for i=0:0.1:10, j=0:0.1:10], color = rgba(1,0,0,1), 
	projection       = camera.projection,
	view     		 = camera.view,
	normalmatrix     = camera.normalmatrix))


while Romeo.window.inputs[:open].value
    Romeo.renderloop(Romeo.window)
end 
GLFW.Terminate()