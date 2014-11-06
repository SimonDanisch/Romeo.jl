using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow


obj = visualize(readall(open("testest.jl")), screen=Romeo.ROOT_SCREEN, model=eye(Mat4)*translationmatrix(Vec3(0f0,800f0,0f0)))
edit(obj[:text], obj)

push!(Romeo.ROOT_SCREEN.renderlist, obj)

while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
end 
GLFW.Terminate()
