using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow


obj = edit(Texture(Float32[1 2 3 4; 5 6 7 8; 9 10 11 12], keepinram=true))
push!(Romeo.ROOT_SCREEN.renderlist, obj)

while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
end 
GLFW.Terminate()
