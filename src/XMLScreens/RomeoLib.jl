module RomeoLib

using SubScreens
using TBCompletedM
using GLVisualize, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow
using GeometryTypes, ColorTypes

export init_romeo, interact_loop,
       clear!,
       setDebugLevels
debugFlagOn  = false
debugLevel   = UInt64(0)

#==       Level (ORed bit values)
           0x01: Show information about user provided function calls
              2: Show debugging information related to pushing onto renderlist
              4: Debug connector
              8: Debug calls to visualize
           0x10: Show progress in fnWalk1 functions (walk subscreen tree)
           0x20: Show progress in fnWalk2 functions (walk subscreen tree)
           0x40: Show progress in fnWalk3 functions (walk subscreen tree)
           0x80: Show progress in fnWalk4 functions (walk subscreen tree)
==#
#==  Set the debug parameters
==#
function setDebugLevels(flagOn::Bool,level::UInt64)
    global debugFlagOn
    global debugLevel
    debugFlagOn = flagOn
    debugLevel  = flagOn ? UInt64(level) : UInt64(0)
end
setDebugLevels(flagOn::Bool,level::Int) = setDebugLevels(flagOn,UInt64(level))
setDebugLevels(flagOn::Bool,level::Int32) = setDebugLevels(flagOn,UInt64(level))
setDebugLevels(flagOn::Bool,level::UInt8) = setDebugLevels(flagOn,UInt64(level))

dodebug(b::UInt8)  = debugFlagOn && ( debugLevel & UInt64(b) != 0 )
dodebug(b::UInt32) = debugFlagOn && ( debugLevel & UInt64(b) != 0 )
dodebug(b::UInt64) = debugFlagOn && ( debugLevel & UInt64(b) != 0 )
@doc """   Empty the vector of renderers passed in argument, 
           and delete individually    each element.
     """   ->
function clear!(x::Vector{RenderObject})
    while !isempty(x)
        value = pop!(x)
        delete!(value)
    end
end
using DebugTools
using ROGeomOps       ## geometric OpenGL transformations on RenderObjects
using VirtualOGLGeom  ## tools to effect transformations on RenderObjects via
                      ## interfaces
using Connectors
using SemXMLSubscreen

@doc """  Performs a number of initializations
          Construct all RenderObjects (suitably parametrized) and inserts them in
          renderlist.
          
          The first argument is a fully a SubScreen (tree, with Rectangles 
          expanded/localized via computeRects  ). The attrib dictionnary is exploited 
          to set up the subscreens; all new objects are referenced via the SubScreen
          tree attrib dictionnaries.

          NOTE: THIS VERSION CORRESPONDS RECURSIVE GRIDDING: CURRENT LIBRARY CODE
     """  -> 
function init_romeo( vObjT::SubScreen ; 
                     pcamSel=true, 
                     builtDict::Dict{Tuple{Symbol,Symbol},Any} = 
                               Dict{Tuple{Symbol,Symbol},Any}() )
    root_area = GLVisualize.ROOT_SCREEN.area
    global_inputs = GLVisualize.ROOT_SCREEN.inputs

    # this enables sub-screen dimensions to adapt to  root window changes:
    # a signal is produced with root window's dimensions on display
    screen_height_width = lift(root_area) do area 
        Vector2{Int}(area.w, area.h)
    end


    # set the subscreens areas as signals focused on subscreen rectangles
    fnWalk1 = function(ssc,indx,misc,info)
           info[:isDecomposed] && return
           ssc.attrib[sigArea ] = 
              lift (GLVisualize.ROOT_SCREEN.area,  screen_height_width) do ar,screenDims
                       RectangleProp(ssc,screenDims) 
                    end
          dodebug(0x10) && println("In fnWalk1 at$indx: sigArea=", ssc.attrib[sigArea ])
    end
    treeWalk!(vObjT,  fnWalk1)

    # Make subscreens of Screen type, each equipped with renderlist
    # We will then put RenderObject in each of the subscreens

    fnWalk2 = function(ssc,indx,misc,info)
         info[:isDecomposed] && return
         ssc.attrib[sigScreen ] =   Screen(GLVisualize.ROOT_SCREEN, area= ssc.attrib[sigArea ])
         dodebug(0x20) && println("In fnWalk2 at$indx: sigScreen=", ssc.attrib[sigScreen ])
    end
    treeWalk!(vObjT,  fnWalk2)

       # The game here: thy shall not call visualize with a RenderObject
       # ( May be this can be simplified if  my proposed patch in 
       # Romeo/src/visualize_interface.jl gets accepted)
@doc """
       This function returns a RenderObject, or an iterable thereof
       having processed its data through visualize if needed. A number of
       cases may occur:
         * NotComplete: screen or camera insertion have caused postponing eval
         * Dict
         * RenderObject
         * Tuple{Vararg{RenderObject}}
"""->
   function visualizeConduit(vo, camera, scr)
      dodebug(0x40) && println("Entering visualizeConduit")
      if isa( vo, NotComplete)
         if haskey(vo.data, :SetPerspectiveCam)
            scr.perspectivecam = camera
            return visualize(vo.what, screen=scr )
          elseif  haskey(vo.data, :doColorChooser)
            return  visualize(vo.what)      
          else 
             error("Unknown or absent key for TBCompleted ")
          end
      end
      if isa(vo, Tuple)
         return map( v -> visualizeConduit( v, camera, scr), vo)
      end

      if isa(vo, RenderObject)
         return vo
      end

      retval = 
           if ! isa(vo,Dict)
               dodebug(0x8) && println("Calling visualize arg type=",typeof(vo))
               visualize(vo, screen=scr)
           else
              # do not visualize RenderObjects!
              if ! (   isa(vo[:render],RenderObject) 
                    || isa(vo[:render],Tuple{Vararg{RenderObject}}))
                 visualize(vo, screen=scr)
              else
                 vo
              end
           end
    
      dodebug(0x40) && println("Exiting visualizeConduit")
      return retval
   end

   # Equip each subscreen with a RenderObject 

    fnWalk3 = function( ssc::SubScreen, 
                        indx::Vector{Tuple{Int64,Int64}}, 
			misc::Dict{Symbol,Any}, info::Dict{Symbol,Any})
       info[:isDecomposed] && return
       haskey(ssc.attrib,RObjFn )  || return

       dodebug(0x40) && println("Entering fnWalk3 at$indx")

       scr = ssc.attrib[sigScreen ]
       # the  selection of signals to drive cameras (in correct subscreen) is from 
       # S.Danisch example  (synchronized subscreens)

       #checks if mouse is inside 
       insidescreen = lift(global_inputs[:mouseposition]) do mpos
             isinside(scr.area.value, mpos...) 
       end
       # creates signals for the camera, which are only active if mouse is inside screen
       camera_input = merge(global_inputs, Dict(
         :mouseposition  => keepwhen(insidescreen, Vector2(0.0), global_inputs[:mouseposition]), 
         :scroll_x       => keepwhen(insidescreen, 0, global_inputs[:scroll_x]), 
         :scroll_y       => keepwhen(insidescreen, 0, global_inputs[:scroll_y]), 
       ))
       #this is the reason we have to go through all this. For the correct 
       #perspective projection, the camera needs the correct screen rectangle.
       camera_input[:window_size] = lift(x->Vector4(x.x, x.y, x.w, x.h),scr.area)

       #default perspective parametrization (may be done better or parametrized)
       eyepos = Vector3{Float32}(2, 2, 2)
       centerScene= Vector3{Float32}(0.0)
       # when the user specifies a rotation we start from an eye aligned with
       # the x axis
       if haskey(ssc.attrib,RORot) 
           eyepos = Vector3{Float32}(3.5, 0, 0)
       end

       # Model space transformations which amount to changes in camera
       # position/center of view
       eyepos ,  centerScene = effVModelGeomCamera(ssc,eyepos, centerScene)

       pcam = PerspectiveCamera(camera_input,eyepos ,  centerScene)
       ocam=  OrthographicCamera(camera_input)

       camera = pcamSel ? pcam : ocam
       # Build the RenderObjects by calling the supplied function
       if dodebug(0x1)
            println("Entering external function:  ssc.attrib[ RObjFn ]", 
                                ssc.attrib[ RObjFn ])
            println(typeof(ssc.attrib[ RObjFn ]))
       end

       if !haskey(ssc.attrib,RObjFnParms)
             vo  = ssc.attrib[ RObjFn ]( scr, camera )
       else
             extra = ssc.attrib[ RObjFnParms ]
             println ("About to process RObjFn with extra parms:", extra )
             sfnName  = Symbol(extra["name"])
             initVal = builtDict[(:sigInitVal,sfnName)]
             showBD(builtDict)

             # this piece of code will need to be improved before
             # we allow multiple signal initialization values
             vo  = ssc.attrib[ RObjFn ]( scr, camera, initVal )

       end
       dodebug(0x1) && println("Exited and returned vo with type:",typeof(vo))


       viz =   visualizeConduit(vo,camera,scr)
       dodebug(0x8) && println("Visualized object of type:",typeof(viz))       
       ssc.attrib[ROProper] = viz


       # Does the user request virtual functions (we need to verify availability or diagnose)
       marker  = haskey(ssc.attrib,ROReqVirtUser) ? ssc.attrib[ROReqVirtUser] : 0
       # Check availability, this will use an external function (in ad hoc module!)
       #TBD!!!
       if  marker  != 0
            if isa(viz,RenderObject) && hasManipVirt(viz, ROReqVirtUser)
               println("Need to check avail of $marker in",
                        manipVirt(viz, ROReqVirtUser)  )
            else
               warn("Cannot check availability of feature $marker in $viz")
            end
       end


       # this way the user can request a dump 
       if haskey(ssc.attrib,RODumpMe)
          println("Dump for object viz of type = ",typeof(viz),"")
          function dumpIntern(viz)
              for k in sort(collect(keys( viz.uniforms)))
                 println("RODumpMe\tuniform\tkey=$k")
	      end
          end
          if isa(viz,Tuple{Vararg{Any}})
             for v in viz
              isa(v,RenderObject) ?  dumpIntern(v) : @show v
             end
          elseif isa(viz,RenderObject)
              dumpIntern(viz)
          else
              @show viz
          end
       end
       dodebug(0x40) &&println("About to push on renderlist typeof:",typeof(viz))
       if isa(viz,Tuple{Vararg{RenderObject}})
            for v in viz
                push!(scr.renderlist, v)
            end
       elseif  isa(viz,Tuple{Vararg{Any}})  
          # here deal with the case of color
          # where a pair (GLAbstraction.RenderObject,
          #               Reactive.Lift{GeometryTypes.Vector4{Float32}})
            for v in viz
                if   isa(v,RenderObject)  push!(scr.renderlist, v)
                     # discard the Lift.... ? Good or Bad??

                     # Here  we set an attribute (we could use a signal)
                     dodebug(0x02) && chkDump(v,true)
                     v.uniforms[:swatchsize]=Input(4.0f0)
                end
            end
       else
            push!(scr.renderlist, viz)
       end
       dodebug(0x40) &&println("Exiting fnWalk3")

    end   # function  fnWalk3

    treeWalk!(vObjT,  fnWalk3)

# 4th pass for  operations which require multiple RO built (so that 
# we do not have to care about order of RO construction
    function fnWalk4( ssc::SubScreen, 
                        indx::Vector{Tuple{Int64,Int64}}, 
			misc::Dict{Symbol,Any}, info::Dict{Symbol,Any})
       info[:isDecomposed] && return
       haskey(ssc.attrib,ROConnects )  || return
       haskey(ssc.attrib,RObjFn )  || return
       dodebug(0x80) && println("Entering fnWalk4 at$indx")


       #recover the connector list
       connectTo::Array{Connector,1}     = ssc.attrib[ROConnects]
       #these connectors are by necessity incomplete, must be completed
       for conn in  connectTo
            conn.to           = ssc.attrib[ROProper]
            #go from screen to RenderObject (is this really needed here ??)
            conn.from         = conn.from.attrib[ROProper]
       end
       dodebug( 0x04 ) &&println("\tAt index=$indx, connector list=$connectTo")
       connect!(connectTo)

       dodebug(0x80) && println("Exiting fnWalk4 at$indx")

    end #  function fnWalk4

    treeWalk!(vObjT,  fnWalk4)


end

# This is the simplest interact loop
function interact_loop()
   println("Into  interact_loop()")
   while GLVisualize.ROOT_SCREEN.inputs[:open].value
      glEnable(GL_SCISSOR_TEST)
      GLVisualize.renderloop(GLVisualize.ROOT_SCREEN)
      sleep(0.01)
   end
   GLFW.Terminate()
end
# This is the interact loop adapted for signal update
# it is inspired from GLVisualize/test/nbody.jl.
# Of course, it uses the material stored in the buildDict directory. 
function interact_loop(builtDict::Dict{Tuple{Symbol,Symbol},Any})
   println("Into  interact_loop(builtDict)")

   # start the render loop asynchronously
   @async renderloop()

   # perform the updates of the signals
   while GLVisualize.ROOT_SCREEN.inputs[:open].value
         performSignalUpdts(builtDict)
   end


   GLFW.Terminate()
end
end # 		module RomeoLib
