using Romeo
obj = visualize(readall(open(Pkg.dir("Romeo", "src", "Romeo.jl"))))
push!(Romeo.RENDER_LIST, obj)
while Romeo.window.inputs[:open].value
  Romeo.renderloop(Romeo.window)
end
GLFW.Terminate()
