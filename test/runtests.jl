using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow

N       = 128
volume  = Float32[sin(x / 12f0)+sin(y / 12f0)+sin(z / 12f0) for x=1:N, y=1:N, z=1:N]
max     = maximum(volume)
min     = minimum(volume)
volume  = (volume .- min) ./ (max .- min)

ws= 700

screen1 = Screen(Romeo.ROOT_SCREEN, area=Input(Rectangle(0,0,ws,ws)))
screen3 = Screen(Romeo.ROOT_SCREEN, area=Input(Rectangle(0,ws,ws,ws)))
screen2 = Screen(Romeo.ROOT_SCREEN, area=Input(Rectangle(ws,0,ws,ws)))
screen4 = Screen(Romeo.ROOT_SCREEN, area=Input(Rectangle(ws,ws,ws,ws)))



obj3 = visualize(rgba(1.0, 0.2, 0.1,1.0), screen=screen3)
obj1 = visualize(Float32[ 0f0  for i=0:10, j=0:10], :zscale, color = obj3[:color], primitive=CUBE(), screen=screen1)

obj2 = edit(obj1[:zscale], screen=screen2)
obj4 = visualize(volume, color=lift(x->Vec3(x[1],x[2],x[3]), obj3[:color]), screen=screen4)


push!(screen1.renderlist, obj1)
push!(screen2.renderlist, obj2)
push!(screen3.renderlist, obj3)
push!(screen4.renderlist, obj4)

while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
    sleep(0.0001)
end 
GLFW.Terminate()