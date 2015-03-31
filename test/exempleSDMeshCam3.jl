using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color, ImmutableArrays

#Note, that you have to change immutable to type in Screen and PerspectiveCamera
#      in reactglfw.jl and GLCamera.jl

function main()
    root_screen = Romeo.ROOT_SCREEN

    screenAarea = lift(root_screen.area) do area
        Rectangle{Int}(0, 0, div(area.w, 2), area.h)
    end 
    screenBarea = lift(root_screen.area) do area
        Rectangle{Int}(div(area.w, 2), 0, div(area.w, 2), area.h)
    end
    global_inputs = root_screen.inputs
    #checks if mouse is inside screenA or B
    insidescreen = lift(global_inputs[:mouseposition]) do mpos
        isinside(screenAarea.value, mpos...) || isinside(screenBarea.value, mpos...) 
    end
    # creates signals for the camera, which are only active if mouse is inside screen
    camera_input = merge(global_inputs, Dict(
        :mouseposition  => keepwhen(insidescreen, Vector2(0.0), global_inputs[:mouseposition]), 
        :scroll_x       => keepwhen(insidescreen, 0, global_inputs[:scroll_x]), 
        :scroll_y       => keepwhen(insidescreen, 0, global_inputs[:scroll_y]), 
    ))
    #this is the reason we have to go through all this. For the correct perspective projection, the camera needs the correct screen rectangle.
    camera_input[:window_size] = lift(x->Vector4(x.x, x.y, x.w, x.h), screenAarea)
    # creates cameras for the sceen with the new inputs
    ocameraA      = OrthographicPixelCamera(camera_input)
    pcameraA      = PerspectiveCamera(camera_input, Vec3(2), Vec3(0))
    camera_input[:window_size] = lift(x->Vector4(x.x, x.y, x.w, x.h), screenBarea)
    # creates cameras for the sceen with the new inputs
    ocameraB      = OrthographicPixelCamera(camera_input)
    pcameraB      = PerspectiveCamera(camera_input, Vec3(2), Vec3(0))
    #make the cameras share the same view matrix (notice, they still have different projection matrices)
    pcameraB.view = pcameraA.view
    #call the ugly Screen constructor
    screenA        = Screen(screenAarea, root_screen, Screen[], root_screen.inputs, RenderObject[], root_screen.hidden, root_screen.hasfocus, pcameraA, ocameraA, root_screen.nativewindow)
    screenB        = Screen(screenBarea, root_screen, Screen[], root_screen.inputs, RenderObject[], root_screen.hidden, root_screen.hasfocus, pcameraB, ocameraB, root_screen.nativewindow)
    push!(root_screen.children, screenA)
    push!(root_screen.children, screenB)

    vizA = visualize(Float32[sin(i)sin(j) for i=0:0.1:5, j=0:0.1:5], primitive=SURFACE(), screen=screenA)
    vizB = visualize(rand(Float32, 10, 13), :zscale,                 primitive=CUBE(),    screen=screenB)

    push!(screenA.renderlist, vizA)
    push!(screenB.renderlist, vizB)

end
main()

while Romeo.ROOT_SCREEN.inputs[:open].value
    glEnable(GL_SCISSOR_TEST)
    Romeo.renderloop(Romeo.ROOT_SCREEN)
    sleep(0.0001)
end
GLFW.Terminate()
