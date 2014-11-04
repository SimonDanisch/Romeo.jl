using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow


N       = 128
volume  = Float32[sin(x / 12f0)+sin(y / 12f0)+sin(z / 12f0) for x=1:N, y=1:N, z=1:N]
max     = maximum(volume)
min     = minimum(volume)
volume  = (volume .- min) ./ (max .- min)

#push!(Romeo.RENDER_LIST, visualize(volume))
#push!(Romeo.RENDER_LIST, visualize(readall(open("../src/Romeo.jl"))))
#push!(Romeo.RENDER_LIST, visualize(Texture(joinpath(homedir(),"Desktop", "random imgs", "jannis.jpg"))))

ab = Screen(Romeo.ROOT_SCREEN, area=Input(Rectangle(100,100,400,400)))
push!(Romeo.ROOT_SCREEN.children, ab)
push!(ab.renderlist, visualize(Float32[0f0 for i=0:0.1:10, j=0:0.1:10], color = rgba(1,0,0,1)))
while Romeo.ROOT_SCREEN.inputs[:open].value
    Romeo.renderloop(Romeo.ROOT_SCREEN)
end 
GLFW.Terminate()