module Romeo

using GLWindow 
using GLAbstraction
using ModernGL
using ImmutableArrays
using Reactive
using GLFW
using Images
using Quaternions
using GLText
using Compat
using Color
using FixedPointNumbers
import Mustache

const sourcedir = Pkg.dir("Romeo", "src")
const shaderdir = joinpath(sourcedir, "shader")

function maxper(v0::Vector3, v1::Vector3)
	return Vector3(max(v0[1], v1[1]),
            max(v0[2], v1[2]),
            max(v0[3], v1[3]))
end
function minper(v0::Vector3, v1::Vector3)
	return Vector3(min(v0[1], v1[1]),
            min(v0[2], v1[2]),
            min(v0[3], v1[3]))
end

Base.minimum{T, NDIM}(x::Array{Vector3{T},NDIM}) = reduce(minper, x)
Base.maximum{T, NDIM}(x::Array{Vector3{T},NDIM}) = reduce(maxper, x)

include(joinpath(     sourcedir, "utils.jl"))
include(joinpath(     sourcedir, "types.jl"))
include_all(joinpath( sourcedir, "display"))
include(joinpath(     sourcedir, "color.jl"))
include_all(joinpath( sourcedir, "share"))
include_all(joinpath( sourcedir, "edit"))
include_all(joinpath( sourcedir, "visualize"))
include(joinpath(     sourcedir, "visualize_interface.jl"))
include(joinpath(     sourcedir, "edit_interface.jl"))

export visualize    # Visualize an object
export edit         # Edit an object

export RGBAU8       # typealias for RGBA ufixed 8 value
export rgba         # function for creating a rgba Float32 color
export rgbaU8       # function for creating a rgba Ufixed8 color

export tohsva       # Convert to HSVA
export torgba       # Converts to RGBA

# Surface Rendering
export mix      # mix colors
export SURFACE  # function that generates a Surface primitive for every datapoint, with an optional gap between the surfaces
export CIRCLE   # function that generates Circular surface primitive for every datapoint
export CUBE     # function that generates Cube primitives for every datapoint
export POINT    # function that generates Point primitives for every datapoint

end # module
