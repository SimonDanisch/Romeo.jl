using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color
function clear!(x::Vector{RenderObject})
    while !isempty(x)
        value = pop!(x)
        delete!(value)
    end
end
global gaggaaa = Texture("pic.jpg")

test = Input("asdasda")
visualize_screen = Romeo.ROOT_SCREEN
lift(test) do x 
	s = symbol(strip(x))
    if isdefined(s)
        value = eval(Main, s)
        if applicable(visualize, value)
            clear!(visualize_screen.renderlist)
            obj     = visualize(value, screen=visualize_screen)
            push!(visualize_screen.renderlist, obj)
        end
    end
    nothing
end

while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
    sleep(0.0001)
    if test.value == "asdasda"
    	push!(test, "gaggaaa")
    end
end
GLFW.Terminate()
