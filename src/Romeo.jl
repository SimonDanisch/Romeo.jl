module Romeo


using GLVisualize, AbstractGPUArray, GLAbstraction, GeometryTypes, Reactive,
      ColorTypes

const sourcedir = Pkg.dir("Romeo", "src")
const shaderdir = joinpath(sourcedir, "shader")

# support for subscreen mgt extensions
const xmldir    =   joinpath(sourcedir, "XMLScreens")
const docutildir=   joinpath(sourcedir,"docUtil")
push!(LOAD_PATH, xmldir)
push!(LOAD_PATH, docutildir)



end # module
