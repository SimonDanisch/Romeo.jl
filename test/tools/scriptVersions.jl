;; This buffer is for notes you don't want to save, and for Lisp evaluation.
;; If you want to create a file, visit that file with C-x C-f,
;; then enter the text in that file's own buffer.

Wow this script is insanely slow...
Well, but it should include all the packages on the right branch..
Sorry for the mess, but there is a lot of prototyping involved here^^

!isa(Pkg.installed("GLWindow"), VersionNumber) && Pkg.add("GLWindow")
Pkg.checkout("GLWindow", "julia04")                                    # OK

!isa(Pkg.installed("GLAbstraction"), VersionNumber) && Pkg.add("GLAbstraction")
Pkg.checkout("GLAbstraction", "julia04")                              # OK

!isa(Pkg.installed("ModernGL"), VersionNumber) && Pkg.add("ModernGL")
Pkg.checkout("ModernGL", "master")                                    # OK

!isa(Pkg.installed("FixedSizeArrays"), VersionNumber) && Pkg.clone("https://github.com/SimonDanisch/FixedSizeArrays.jl.git")
Pkg.checkout("FixedSizeArrays", "master")                             # OK

!isa(Pkg.installed("GeometryTypes"), VersionNumber) && Pkg.clone("https://github.com/JuliaGeometry/GeometryTypes.jl.git")
Pkg.checkout("GeometryTypes", "master")                               # OK

!isa(Pkg.installed("ColorTypes"), VersionNumber) && Pkg.clone("https://github.com/SimonDanisch/ColorTypes.jl.git")
Pkg.checkout("ColorTypes", "master")                                  # OK

!isa(Pkg.installed("Reactive"), VersionNumber) && Pkg.add("Reactive")
Pkg.checkout("Reactive", "master")                                    # OK

!isa(Pkg.installed("GLFW"), VersionNumber) && Pkg.add("GLFW")
Pkg.checkout("GLFW", "julia04")                                        # OK

!isa(Pkg.installed("Compat"), VersionNumber) && Pkg.add("Compat")
Pkg.checkout("Compat", "master")                                      # OK updated

!isa(Pkg.installed("ImageIO"), VersionNumber) && Pkg.clone("https://github.com/JuliaIO/ImageIO.jl.git")
Pkg.checkout("ImageIO", "master")                                     # OK 


!isa(Pkg.installed("FileIO"), VersionNumber) && Pkg.clone("https://github.com/JuliaIO/FileIO.jl.git")
Pkg.checkout("FileIO", "master")                                     # OK 

!isa(Pkg.installed("MeshIO"), VersionNumber) && Pkg.clone("https://github.com/JuliaIO/MeshIO.jl.git")
Pkg.checkout("MeshIO", "master")                                     # OK

!isa(Pkg.installed("Meshes"), VersionNumber) && Pkg.add("Meshes")
Pkg.checkout("Meshes", "meshes2.0") #OK

!isa(Pkg.installed("AbstractGPUArray"), VersionNumber) && Pkg.clone("https://github.com/JuliaGPU/AbstractGPUArray.git")
Pkg.checkout("AbstractGPUArray", "master) #OK
