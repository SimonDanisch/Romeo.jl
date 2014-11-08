using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow


obj, inp = edit(Input(Vec4(0)))

push!(Romeo.ROOT_SCREEN.renderlist, obj)

while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
end 
GLFW.Terminate()
