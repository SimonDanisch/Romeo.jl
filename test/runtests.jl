using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow

N       = 128
volume  = Float32[sin(x / 12f0)+sin(y / 12f0)+sin(z / 12f0) for x=1:N, y=1:N, z=1:N]
max     = maximum(volume)
min     = minimum(volume)
volume  = (volume .- min) ./ (max .- min)


screen1 = Screen(Romeo.ROOT_SCREEN, area=Input(Rectangle(0,0,250,250)))
screen3 = Screen(Romeo.ROOT_SCREEN, area=Input(Rectangle(0,250,250,250)))

screen2 = Screen(Romeo.ROOT_SCREEN, area=Input(Rectangle(250,0,250,250)))
screen4 = Screen(Romeo.ROOT_SCREEN, area=Input(Rectangle(250,250,250,250)))

obj1 = visualize(Float32[(sin(i)+sin(j))/4f0 for i=0:0.1:10, j=0:0.1:10], color = rgba(1,0,0,1), screen=screen1)
obj2 = visualize(volume, screen=screen2)
obj3 = visualize(rgba(0.2, 0.3, 0.1,1.0), screen=screen3)
obj4 = visualize(Texture(joinpath(homedir(),"Desktop", "iso.png")), screen=screen4)

#push!(screen1.renderlist, obj1)
push!(screen2.renderlist, obj2)
push!(screen3.renderlist, obj3)
#push!(screen4.renderlist, obj4)

while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
end 
GLFW.Terminate()