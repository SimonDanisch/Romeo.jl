using GLWindow, ModernGL, GLAbstraction, Romeo, Color, Images, ImmutableArrays

begin
local const BOUNDINGBOX_FRAMEBUFFER = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, BOUNDINGBOX_FRAMEBUFFER)
framebuffsize = [1,1]

minbuffer = Texture(Vec4, framebuffsize)
maxbuffer = Texture(Vec4, framebuffsize)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, minbuffer.id, 0)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, maxbuffer.id, 0)
println(GLENUM(glCheckFramebufferStatus(GL_FRAMEBUFFER)).name)
glBindFramebuffer(GL_FRAMEBUFFER, Romeo.RENDER_FRAMEBUFFER)


function boundingboxshader(name::String; view::Dict{ASCIIString, ASCIIString} = Dict{ASCIIString, ASCIIString}(), attributes::Dict{Symbol, Any}=Dict{Symbol, Any}())
    TemplateProgram(
    joinpath(shaderdir, "boundingbox", name), joinpath(shaderdir, "boundingbox", "boundingbox.frag"), 
    view=view, attributes=attributes, fragdatalocation=[(0, "minbuffer"),(1, "maxbuffer")]
  )
end
function boundingboxshader(vert::String, frag::String; view::Dict{ASCIIString, ASCIIString} = Dict{ASCIIString, ASCIIString}(), attributes::Dict{Symbol, Any}=Dict{Symbol, Any}())
    TemplateProgram(
    joinpath(shaderdir, "boundingbox", vert), joinpath(shaderdir, "boundingbox", frag), 
    view=view, attributes=attributes, fragdatalocation=[(0, "minbuffer"),(1, "maxbuffer")]
  )
end

function boundingbox(renderobject)
    renderobject.boundingbox(renderobject)
end

const FLOAT32MIN = -999999999999999999999999f0
function boundingbox_gpu(renderobject::RenderObject)
	glClearColor(FLOAT32MIN, FLOAT32MIN, FLOAT32MIN, FLOAT32MIN)
    glBindFramebuffer(GL_FRAMEBUFFER, BOUNDINGBOX_FRAMEBUFFER)
    glViewport(0,0, framebuffsize...)
    glClampColor(GL_CLAMP_VERTEX_COLOR, GL_FALSE)
    glClampColor(GL_CLAMP_READ_COLOR, GL_FALSE)
    glClampColor(GL_CLAMP_FRAGMENT_COLOR, GL_FALSE)
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
    glClear(GL_COLOR_BUFFER_BIT)

    glDisable(GL_DEPTH_TEST)
    glDisable(GL_CULL_FACE)
    glDisable(GL_ALPHA_TEST)
    glEnable(GL_BLEND)
    glBlendFunc(GL_ONE, GL_ONE)
    glBlendEquation(GL_MAX)

    program = renderobject.vertexarraybb.program
    glUseProgram(program.id)
    for (key,value) in program.uniformloc
        gluniform(value..., renderobject.uniforms[key])
    end
    if haskey(renderobject.postrenderfunctions, render)
        render(renderobject.vertexarraybb, GL_POINTS)
    elseif haskey(renderobject.postrenderfunctions, renderinstanced)
        renderinstanced(renderobject.vertexarraybb, renderobject[:postrender, renderinstanced][2], GL_POINTS)
    else
        error("RenderObject doesn't have a renderfunction. RenderObject: \n", renderobject)
    end

    println("min: ", -data(minbuffer))
    println("max: ", data(maxbuffer))
    glBindFramebuffer(GL_FRAMEBUFFER, Romeo.RENDER_FRAMEBUFFER)
    glClampColor(GL_CLAMP_VERTEX_COLOR, GL_TRUE)
    glClampColor(GL_CLAMP_READ_COLOR, GL_TRUE)
    glClampColor(GL_CLAMP_FRAGMENT_COLOR, GL_TRUE)
end
end

const testdata = [rgba(0f0,1f0,0f0,1f0) for i=1:9, j=1:11]
obj = visualize(rgba(0,0,0,1))
obj1 = visualize("alksjdlaskjdlkasjd\n"^15)

println(boundingbox(obj))
println(boundingbox(obj1))

GLFW.Terminate()