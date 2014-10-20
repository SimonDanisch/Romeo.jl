module Romeo

using GLWindow, GLAbstraction, ModernGL, ImmutableArrays, Reactive, GLFW, Images, Quaternions, GLText, Compat
import Mustache


const sourcedir = Pkg.dir("Romeo", "src")
const shaderdir = joinpath(sourcedir, "shader")

function include_all(folder::String)
    for file in readdir(path)
        if endswith(file, ".jl")
            include(joinpath(path, file))
        end
    end
end
mergedefault!{S}(style::Style{S}, styles, customdata) = merge!(styles[S], Dict{Symbol, Any}(customdata))


include(joinpath(sourcedir,         "types.jl"))
include_all(joinpath(sourcedir,     "window"))
include(joinpath(sourcedir,         "color.jl"))
include(joinpath(sourcedir,         "visualize_interface.jl"))
include(joinpath(sourcedir,         "edit_interface.jl"))
include_all(joinpath(sourcedir,     "share"))
include_all(joinpath(sourcedir,     "edit"))
include_all(joinpath(sourcedir,     "visualize"))
include(joinpath(sourcedir,         "exports.jl"))




global const RENDER_LIST = RenderObject[]


function visualize(args...;keyargs...)
    obj = visualize(args...;keyargs...)
    push!(RENDER_LIST, obj)
    obj
end
function visualize(x::RenderObject)
    push!(RENDER_LIST, x)
    x
end

clear!() = empty!(RENDER_LIST)




end # module
