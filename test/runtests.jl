using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color


area1 = lift(Romeo.ROOT_SCREEN.area) do x
	Rectangle(0,0,div(x.w,7)*3, x.h)
end
area2 = lift(Romeo.ROOT_SCREEN.area) do x
	Rectangle(div(x.w,7)*3,0,div(x.w,7)*3, x.h)
end
area3 = lift(Romeo.ROOT_SCREEN.area) do x
	Rectangle(div(x.w,7)*6,0,div(x.w,7), x.h)
end


screen1 = Screen(Romeo.ROOT_SCREEN, area=area1)
screen3 = Screen(Romeo.ROOT_SCREEN, area=area2)
screen2 = Screen(Romeo.ROOT_SCREEN, area=area3)

w_height = lift(Romeo.ROOT_SCREEN.area) do x
	x.h
end
transl(offset) = lift(w_height) do x
translationmatrix(Vec3(30,x-offset,0))
end
trans1 = transl(30)
trans2 = transl(250)

trans3 = transl(700)
trans4 = transl(800)
trans5 = transl(900)
trans6 = transl(1000)



obj1 = visualize(readall(open("runtests.jl")), model=trans1, screen=screen1)
obj3 = visualize(Float32[0f0 for i=1:10, j=1:10], :zscale, primitive=CUBE(), screen=screen3)
obj = edit(obj3, screen=screen2)
#text = edit(obj1[:text], obj1)


push!(screen1.renderlist, obj1)
append!(screen2.renderlist, obj)
push!(screen3.renderlist, obj3)
glClearColor(0,0,0,0)

while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
    sleep(0.0001)
end
GLFW.Terminate()

