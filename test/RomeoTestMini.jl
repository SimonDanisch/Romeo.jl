#==
   Minimal example problem with plot of 3D data
   Command line:
     Julia4 RomeoTestMini.jl      : shows pb with 3D data
     Julia4 RomeoTestMini.jl any args here   : works with 2D Plot
==#
using Romeo, GLVisualize, AbstractGPUArray, GLAbstraction, GeometryTypes, Reactive,
      ColorTypes, Meshes, MeshIO, GLWindow, ModernGL

function mkVol(screen)
   npts3D = 12
   function plotFn3D(i,j,k)
         x = Float32(i)/Float32(npts3D)-0.5 
         y = Float32(j)/Float32(npts3D)-0.5 
         z = Float32(k)/Float32(npts3D)-0.5 

         ret = if ( x>=0 ) && ( x>=y)
                   2*x*x+3*y*y+z*z
               elseif ( x<0) 
                   2*sin(2.0*3.1416*x)*sin(3.0*3.1416*y)
               else
                   9*x*y*z
               end
          ret
   end
   visualize( Float32[ plotFn3D(i,j,k) for i=0:npts3D, 
                                   j=0:npts3D, k=0:npts3D ], screen=screen)
end

function mkSurf(screen)
    visualize(Float32[sin(i)sin(j) for i=0:0.1:5,
                                       j=0:0.1:5],  :surface,
                                       screen=screen)
end    

function setup(dovol)
    root_screen = GLVisualize.ROOT_SCREEN

    screenArea = lift(root_screen.area) do area
        Rectangle{Int}(0, 0, area.w, area.h)
    end 

    camera_inputs = root_screen.inputs
    camera_inputs[:window_size] = lift(x->Vector4(x.x, x.y, x.w, x.h), screenArea)
    # creates cameras for the sceen with the new inputs
    ocamera      = OrthographicPixelCamera(camera_inputs)
    pcamera      = PerspectiveCamera(camera_inputs, Vec3(2), Vec3(0))

    #call the ugly Screen constructor
    screen        = Screen(screenArea, root_screen, Screen[],
                           root_screen.inputs, RenderObject[],
                           root_screen.hidden, root_screen.hasfocus,
                           pcamera, ocamera, root_screen.nativewindow)
    push!(root_screen.children, screen)

    viz = dovol ?     mkVol(screen)    : mkSurf(screen)

    push!(screen.renderlist, viz)

end

# Select version
length(ARGS) <= 1 ? setup(true) : setup(false)


#== This works
renderloop()
==#

#   Is this better than renderloop() ???

while GLVisualize.ROOT_SCREEN.inputs[:open].value
    glEnable(GL_SCISSOR_TEST)
    GLVisualize.renderloop(GLVisualize.ROOT_SCREEN)
    sleep(0.0001)
end

GLFW.Terminate()




