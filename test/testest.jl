using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow


obj = edit(Texture(rand(Float32, 4,4), keepinram=true))
push!(Romeo.ROOT_SCREEN.renderlist, obj)

while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
end 
GLFW.Terminate()
end