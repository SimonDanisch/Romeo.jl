using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color, ImmutableArrays

function main()
    root_area = Romeo.ROOT_SCREEN.area
    nx = 4 # three screens for x /width
    ny = 3 # four screens for y /height
    screen_height_width = lift(root_area) do area 
        Vector2{Int}(div(area.w, nx), div(area.h, ny))
    end
    pic = Texture("pic.jpg")
    for x=0:nx-1, y=0:ny-1
        area = lift(Romeo.ROOT_SCREEN.area, screen_height_width) do root_area, wh
            xstart = wh[1]*x
            ystart = wh[2]*y
            Rectangle{Int}(xstart, ystart, wh[1], wh[2])
        end
        screen  = Screen(Romeo.ROOT_SCREEN, area=area)
        viz     = visualize(pic, screen=screen)
        push!(screen.renderlist, viz)
    end

end
main()

while Romeo.ROOT_SCREEN.inputs[:open].value
    glEnable(GL_SCISSOR_TEST)
    Romeo.renderloop(Romeo.ROOT_SCREEN)
    sleep(0.0001)
end
GLFW.Terminate()
