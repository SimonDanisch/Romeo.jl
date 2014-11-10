using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow
obj = visualize(Float32[rand(Float32)  for i=0:10, j=0:10], color = rgba(1,0,0,1))
println(obj)
push!(Romeo.ROOT_SCREEN.renderlist, obj)

while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
    sleep(0.0001)
end 
GLFW.Terminate()