module SubScreensModule
# this module is provided to test the XML referencing mechanism
# in some *.xml file in ./test

export doPlot2D, doPlot3D

abstract Screen
abstract Camera

   # try with a plot
   npts = 50 
   function plotFn2D(i,j)
         x = Float32(i)/Float32(npts)-0.5 
         y = Float32(j)/Float32(npts)-0.5 
         ret = if ( x>=0 ) && ( x>=y)
                   4*x*x+2*y*y
               elseif ( x<0) 
                   2*sin(2.0*3.1416*x)*sin(3.0*3.1416*y)
               else
                   0.0
               end
          ret
   end
   function doPlot2D (sc::Screen,cam::Camera)
           println("Entered doPlot2D")
           ret = TBCompleted ( Float32[ plotFn2D(i,j)  for i=0:npts, j=0:npts ],
                         nothing, Dict{Symbol,Any}(:SetPerspectiveCam => true)
                       )
           println("Exit doPlot2D returning")
           ret
   end  
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
   function doPlot3D (sc::Screen,cam::Camera)
           println("Entered doPlot3D")
           dd = Dict{Symbol,Any}(:SetPerspectiveCam => true) 
           ret= TBCompleted ( Float32[ plotFn3D(i,j,k) for i=0:npts3D, 
                                   j=0:npts3D, k=0:npts3D ],
                         nothing, dd)
           println("Exit doPlot3D returning")
           ret
   end  

end # module SubScreensModule
