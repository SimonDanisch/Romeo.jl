using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color
function clear!(x::Vector{RenderObject})
    while !isempty(x)
        value = pop!(x)
        delete!(value)
    end
end
global gaggaaa = Texture("pic.jpg")
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

    const sourcecode  = visualize("barplot = [(sin(i)+cos(j))/4 for i=1:12, j=1:10]", model=source_offset, screen=sourcecode_screen)
    search      = visualize("barplot\n", model=search_offset, color=rgba(0.9,0,0.2,1), screen=search_screen)
    barplot     = visualize(Float32[(sin(i)+cos(j))/4f0 for i=1:12, j=1:10], :zscale, primitive=CUBE(), screen=visualize_screen)
    edit_obj    = edit(barplot, screen=edit_screen)
    viz, source_text = edit(sourcecode[:text], sourcecode)
    viz, search_text = edit(search[:text], search)

    lift(search_text) do x
        s = symbol(strip(x))
        if isdefined(s)
            value = eval(Main, s)
            if applicable(visualize, value)
                clear!(visualize_screen.renderlist)
                obj = visualize(value)
                push!(visualize_screen.renderlist, obj)
            end
        end
        nothing
    end
    push!(sourcecode_screen.renderlist, sourcecode)
    append!(edit_screen.renderlist, edit_obj)
    push!(visualize_screen.renderlist, barplot)
    push!(search_screen.renderlist, search)
    glClearColor(0,0,0,0)
end

init_romeo()

while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
    sleep(0.0001)
end
GLFW.Terminate()

