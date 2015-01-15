using Gadfly, Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color, Distributions
function clear!(x::Vector{RenderObject})
	while !isempty(x)
		value = pop!(x)
		delete!(value)
	end
end

const taskqueue = Any[]
function viz(func::Function, args...; custumizations...)
	signals = map(args) do x
		isa(x, Signal) ? x : Input(x)
	end
	function execute(x...)
		func(x...)
	end
	visobj = lift(execute, signals...)
	returnobj = visualize(visobj.value; custumizations...)
	lift(visobj) do vis
		if isempty(taskqueue)
			push!(taskqueue, @async visualize(vis; custumizations...))
		elseif length(taskqueue) == 1
			push!(taskqueue, vis)
		elseif length(taskqueue) == 2
			if istaskdone(first(taskqueue))
				empty!(taskqueue)
				push!(taskqueue, @async visualize(vis; custumizations...))
			else
				taskqueue[2] = vis
			end
		end
		returnobj
	end
	returnobj
end

function init_romeo()
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
	D = Dict{Symbol, Any}(
		:a => Input(1f0),
		:b => Input(10f0)
	)
	signals = edit(D, screen=sourcecode_screen)
	barplot = viz(plot, sin, D[:a], D[:b], screen=visualize_screen)

	append!(sourcecode_screen.renderlist, signals)
	push!(visualize_screen.renderlist, barplot)
end

init_romeo()
glClearColor(1,1,1,1)
while Romeo.ROOT_SCREEN.inputs[:open].value
	Romeo.renderloop(Romeo.ROOT_SCREEN)
	sleep(0.0001)
end
GLFW.Terminate()

