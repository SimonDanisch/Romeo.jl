using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color
function clear!(x::Vector{RenderObject})
    while !isempty(x)
        value = pop!(x)
        delete!(value)
    end
end
global gaggaaa = Texture("pic.jpg")

function dropequal(a::Signal)
    is_equal = foldl((false, a.value), a) do v0, v1
        (v0[2] == v1, v1)
    end
    dropwhen(lift(first, is_equal), a.value, a)
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

    searchinput = Input("barplot")

    const sourcecode  = visualize("barplot = Float32[(sin(i)+cos(j))/4 for i=1:12, j=1:10]\n", model=source_offset, screen=sourcecode_screen)
    search            = visualize("barplot\n", model=search_offset, color=rgba(0.9,0,0.2,1), screen=search_screen)
    viz, source_text  = edit(sourcecode[:text], sourcecode)
    viz, search_text  = edit(search[:text], search)

    should_eval = dropequal(lift(Romeo.ROOT_SCREEN.inputs[:buttonspressed]) do keyset
        keyset == IntSet(GLFW.KEY_ENTER, GLFW.KEY_LEFT_CONTROL)
    end)

    lift(source_text, should_eval) do source, seval
        expr = parse(strip(source), raise=false)
        if seval
            if expr.head != :error
                eval(Main, expr)
            else 
                println(expr)
            end
        end
        nothing
    end
    lift(search_text) do x
        s = symbol(strip(x))
        if isdefined(s)
            value = eval(Main, s)
            if applicable(visualize, value)
                clear!(visualize_screen.renderlist)
                obj = visualize(value, screen=visualize_screen)
                push!(visualize_screen.renderlist, obj)
            end
        end
        nothing
    end
    push!(sourcecode_screen.renderlist, sourcecode)
    push!(search_screen.renderlist, search)
    glClearColor(0,0,0,0)
end

init_romeo()
while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
    sleep(0.0001)
end
GLFW.Terminate()

