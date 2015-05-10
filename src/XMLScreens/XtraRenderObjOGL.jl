module XtraRenderObjOGL

using GLVisualize, GLFW, GLAbstraction, Reactive, ModernGL, GLWindow, ColorTypes
using GeometryTypes
using Compat
#using DocCompat


export  mkCube


# for now, we found a ready made cube
function mkCubeShape()
     vertices, uv, indexes = gencube(1,1,1)
     return ( vertices, uv, indexes)
end
# inline shader construction in the same style e as oglExample2.jl
# (snippets provided  by S.Danisch)

function mkCube(screen,camera)
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
cubeFrag="""
{{GLSL_VERSION}}


{{in}} vec3 vert_color; // gets automatically interpolated per fragment (fragment--> pixel)

{{out}} vec4 frag_color;
void main(){
   	frag_color = vec4(vert_color, 1); // put in transparency
}
"""
cubeLineVert="""
{{GLSL_VERSION}}

{{in}} vec3 vertex;

uniform mat4 projectionview;

void main(){
   	gl_Position = projectionview * vec4(vertex, 1.0);
}
"""
cubeLineFrag="""
{{GLSL_VERSION}}

{{out}} vec4 frag_color;
void main(){
   	frag_color = vec4(0.5,0.5,0.5,1);
}
"""
        # build the shader from inlined GLSL
	lineshader 	= TemplateProgram(cubeLineVert, cubeLineFrag, 
                                         "Cube-linevert", "Cube-linefrag")
	shader 		= TemplateProgram(cubeVert, cubeFrag, "Cube-vert", "Cube-frag")

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
        return (robj,robjl)
        # TBD LOOK AT THIS
end

end # module XtraRenderObjOGL
