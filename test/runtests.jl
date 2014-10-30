using Romeo, GLFW

N       = 128
volume  = Float32[sin(x / 12f0)+sin(y / 12f0)+sin(z / 12f0) for x=1:N, y=1:N, z=1:N]
max     = maximum(volume)
min     = minimum(volume)
volume  = (volume .- min) ./ (max .- min)

obj = visualize(volume)
push!(Romeo.RENDER_LIST, obj)
while Romeo.window.inputs[:open].value
    Romeo.renderloop(Romeo.window)
end 
GLFW.Terminate()