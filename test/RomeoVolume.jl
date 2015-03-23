# --line 8808 --  -- from : "BigData.pamphlet"  
using DocCompat

# try to avoid the numerous "deprecated warnings/messages"
using ManipStreams
(os,ns) =  redirectNewFWrite("/tmp/julia.redirected")

using Romeo, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, Color
using ImmutableArrays
    #  Loading GLFW opens the window
using Compat

include("../src/docUtil/RomeoLib.jl")


# --line 8825 --  -- from : "BigData.pamphlet"  
function mkSubScrGeom()
    ## Build subscreens, use of screen_height_width permits to
    ## adapt subscreen dimensions to changes in  root window  size
    subScreenGeom = if isless(VERSION, VersionNumber(0,4))
            prepSubscreen( [4,1]::Vector, [1,4]::Vector )
    else
            prepSubscreen( Vector([4,1]), Vector([1,4]))
    end
end

# --line 5521 --  -- from : "BigData.pamphlet"  
# for now, we found a ready made cube
function mkCubeShape()
     vertices, uv, indexes = gencube(1,1,1)
     return ( vertices, uv, indexes)
end
# --line 5529 --  -- from : "BigData.pamphlet"  
# inline shader construction in the same style e as oglExample2.jl
# (snippets provided  by S.Danisch)
@doc """
      Create a RenderObject containing Cube(s)
      WARNING:in this design we return an incomplete RenderObject, mvp missing!!
""" ->
function mkCube()
# --line 5639 --  -- from : "BigData.pamphlet"  
cubeVert="""
{{GLSL_VERSION}}

{{in}} vec3 vertex;
{{in}} vec3 color;

{{out}} vec3 vert_color;

uniform mat4 projectionview;

void main(){
	vert_color = color;
   	gl_Position = projectionview * vec4(vertex, 1.0);
}
"""
# --line 5657 --  -- from : "BigData.pamphlet"  
cubeFrag="""
{{GLSL_VERSION}}


{{in}} vec3 vert_color; // gets automatically interpolated per fragment (fragment--> pixel)

{{out}} vec4 frag_color;
void main(){
   	frag_color = vec4(vert_color, 1); // put in transparency
}
"""
# --line 5671 --  -- from : "BigData.pamphlet"  
cubeLineVert="""
{{GLSL_VERSION}}

{{in}} vec3 vertex;

uniform mat4 projectionview;

void main(){
   	gl_Position = projectionview * vec4(vertex, 1.0);
}
"""
# --line 5685 --  -- from : "BigData.pamphlet"  
cubeLineFrag="""
{{GLSL_VERSION}}

{{out}} vec4 frag_color;
void main(){
   	frag_color = vec4(0.5,0.5,0.5,1);
}
"""
# --line 5543 --  -- from : "BigData.pamphlet"  
        # build the shader from inlined GLSL
	lineshader 	= TemplateProgram(cubeLineVert, cubeLineFrag, 
                                         "Cube-linevert", "Cube-linefrag")
	shader 		= TemplateProgram(cubeVert, cubeFrag, "Cube-vert", "Cube-frag")

# --line 5551 --  -- from : "BigData.pamphlet"  
        v,uv,i =mkCubeShape()
        
        println("In mkCube() : ",  typeof(v), "\t", typeof(uv), "\t", typeof(i) )
        println("       type shaders=\t", typeof(shader),"\t",typeof(lineshader) )
        println("\tv=$v")
        println("\tuv=$uv")
        println("\ti=$i")
        println("\tshader=$shader\n")
        println("\tlineshader=$lineshader\n+++  End of mkCube output +++\n")

        robj = RenderObject(@compat(Dict(
                        :vertex                   => GLBuffer(v,3),
                        :indexes                  => indexbuffer(i),
                        :color                    => Float32[0.1,.6,.6, 1.0],
                        :bg_color                 => Input(Vec4(0.3, 0.3, 1, 0.5)),
                        # try to do without camera, so that this is an incomplete RenderObject
                        :projectionview           => nothing
                )), shader)        

        robjl = RenderObject(@compat(Dict(
                        :vertex                   => GLBuffer(v,3),
                        :indexes                  => indexbuffer(i),
                        :color                    => Float32[0.6,.1,.6, 1.0],
                        :bg_color                 => Input(Vec4(0.3, 0.3, 1, 0.5)),
                        # try to do without camera, so that this is an incomplete RenderObject
                        :projectionview           => nothing
                )), lineshader)        

         return  map ((robj,robjl)) do ro
                     TBCompleted(ro,nothing)
                end

end

# --line 5588 --  -- from : "BigData.pamphlet"  
# inline shader construction in the same style e as oglExample2.jl
# (snippets provided  by S.Danisch)

function mkCube(screen,camera)
# --line 5639 --  -- from : "BigData.pamphlet"  
cubeVert="""
{{GLSL_VERSION}}

{{in}} vec3 vertex;
{{in}} vec3 color;

{{out}} vec3 vert_color;

uniform mat4 projectionview;

void main(){
	vert_color = color;
   	gl_Position = projectionview * vec4(vertex, 1.0);
}
"""
# --line 5657 --  -- from : "BigData.pamphlet"  
cubeFrag="""
{{GLSL_VERSION}}


{{in}} vec3 vert_color; // gets automatically interpolated per fragment (fragment--> pixel)

{{out}} vec4 frag_color;
void main(){
   	frag_color = vec4(vert_color, 1); // put in transparency
}
"""
# --line 5671 --  -- from : "BigData.pamphlet"  
cubeLineVert="""
{{GLSL_VERSION}}

{{in}} vec3 vertex;

uniform mat4 projectionview;

void main(){
   	gl_Position = projectionview * vec4(vertex, 1.0);
}
"""
# --line 5685 --  -- from : "BigData.pamphlet"  
cubeLineFrag="""
{{GLSL_VERSION}}

{{out}} vec4 frag_color;
void main(){
   	frag_color = vec4(0.5,0.5,0.5,1);
}
"""
# --line 5599 --  -- from : "BigData.pamphlet"  
        # build the shader from inlined GLSL
	lineshader 	= TemplateProgram(cubeLineVert, cubeLineFrag, 
                                         "Cube-linevert", "Cube-linefrag")
	shader 		= TemplateProgram(cubeVert, cubeFrag, "Cube-vert", "Cube-frag")

# --line 5607 --  -- from : "BigData.pamphlet"  
        v,uv,i =mkCubeShape()
        robj = RenderObject(@compat(Dict(
                 :vertex                  => GLBuffer(v,3),
                 :indexes                 => indexbuffer(i),
                 :color                   => Float32[0.7,.1,.1, 1.0],
                 :bg_color                => Input(Vec4(0.3, 0.3, 1, 0.5)),
                 :projectionview          => camera.projectionview                            
                )), shader)        

        prerender!(robj, glDisable, GL_DEPTH_TEST, glDisable, GL_CULL_FACE, enabletransparency)
        postrender!(robj, render, robj.vertexarray)

        robjl = RenderObject(@compat(Dict(
                 :vertex                  => GLBuffer(v,3),
                 :indexes                 => indexbuffer(i),
                 :color                   => Float32[0.1,.6,.6, 1.0],
                 :bg_color                => Input(Vec4(0.3, 0.3, 1, 0.5)),
                 :projectionview          => camera.projectionview                            
                )), lineshader)        

        prerender!(robjl, glDisable, GL_DEPTH_TEST, glDisable, GL_CULL_FACE, enabletransparency)
        postrender!(robjl, render, robjl.vertexarray, GL_LINES)

        #chkDump(robj,true)
        #chkDump(robjl,true)

        return (robj,robjl)
end

# --line 8844 --  -- from : "BigData.pamphlet"  
@doc """
        This function fills the (global) vizObjArray  with the various
        render objects that we wish to show. 
        The corresponding geometry is built in subScreenGeom directly in 
        init_romeo (it contains the (lifted) geometry elements following the
        window changes).

        The argument onlyImg is here for debugging , when true we show only
        the same image in all grid positions.
     """  ->
function init_graph_grid(onlyImg::Bool)
   vizObjArray = Array(Any,2,2)
            #elements are either Dicts or render??(what type?) 

   # try with a plot 
   plt = Float32[rand(Float32)  for i=0:50, j=0:50]
            # color = rgba(1.0,0.0,0.0,0.4) )
            #  notice that the visualize act is done in init_romeo()

   # put cats all over the place!!!
   pic = Texture("pic.jpg")

   # volume : try with a cube (need to figure out how to make this)
   vol =  mkCube()

            # rows go from bottom to top, columns from left to right on screen
   vizObjArray[1,1] = pic
   vizObjArray[1,2] = onlyImg ? pic :
                                @compat Dict{Symbol,Any}(:render  => vol, 
                                    :color   => rgba(1.0,0.0,0.0,0.4))
   vizObjArray[2,2] = pic
   vizObjArray[2,1] = onlyImg ? pic :
                                @compat Dict{Symbol,Any}(:render  => plt, 
                                    :color   => rgba(1.0,0.0,0.0,0.4))
            # init_romeo has the ability to set any attribute in visualize
   return vizObjArray
end  

# --line 8886 --  -- from : "BigData.pamphlet"  
@doc """
       Does the real work, main only deals with the command line options
     """ ->
function realMain(onlyImg::Bool)
   init_glutils()

   vizObjArray = init_graph_grid(onlyImg)
   subScreenGeom = mkSubScrGeom()
   init_romeo( subScreenGeom, vizObjArray)
   interact_loop()
end


# --line 8902 --  -- from : "BigData.pamphlet"  
@doc """
       Does the real work, simple variant
     """ ->
function realMainSimple(onlyImg::Bool)
   init_glutils()   # defined in GLAbstraction/GLInit
                    # in practice loads registerd shaders

   renderObjFn = 
     if onlyImg
       (sc,cam) -> Texture("pic.jpg")
     else
       (sc,cam) -> mkCube(sc,cam) # this is a function object, since
                  # we cannot evaluate before we know the screen 
     		  # and we left camera parametrization in init_romeo_single
     end
   init_romeo_single(renderObjFn)
   ###
      # Look into the Romeo.ROOT_SCREEN
      println("Romeo.ROOT_SCREEN")
      println(Romeo.ROOT_SCREEN)
      println("+++ This is it !! +++")
   ###
   interact_loop()
end

# --line 8931 --  -- from : "BigData.pamphlet"  
# parse arguments, so that we have some flexibility to vary tests on the command line.
using ArgParse

function main(args)
     s = ArgParseSettings(description = "Test of Romeo with grid of objects")   
     @add_arg_table s begin
       "--img","-i"   
               help="Use image instead of other graphics/scenes"
               action = :store_true
       "--cube", "-c"
               help="Test with a single cube in root window/screen"
               action = :store_true
       "--debug","-d"
               help="show debugging output (in particular from GLRender)"
               arg_type = Int
     end    

     s.epilog = """
          More explanations to come here
     """
    parsed_args = parse_args(s) # the result is a Dict{String,Any}

    onlyImg        = parsed_args["img"]
    cubeSimple     = parsed_args["cube"]

    if parsed_args["debug"] != nothing
          GLAbstraction.setDebugLevels( true,  parsed_args["debug"])
          GLWindow.setDebugLevels( true,  parsed_args["debug"])
    end

    ### NOW, run the program 
    cubeSimple ?   realMainSimple(onlyImg) : realMain(onlyImg)    
end

main(ARGS)

restoreErrStream(os)
close(ns)

