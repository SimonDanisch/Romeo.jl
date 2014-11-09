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




function lollyy{T, ColorDim, NDim}(t::Texture{T, ColorDim, NDim})
    result = Array(T, t.dims...)
    glBindTexture(t.texturetype, t.id)
    glGetTexImage(t.texturetype, 0, t.format, t.pixeltype, result)
    return result
end
glClearColor(0,0,0,0)

glClampColor(GL_CLAMP_VERTEX_COLOR, GL_FALSE);
glClampColor(GL_CLAMP_READ_COLOR, GL_FALSE);
glClampColor(GL_CLAMP_FRAGMENT_COLOR, GL_FALSE);

function boundingbox(renderobject::RenderObject)
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
    glBlendEquation(GL_MIN)

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

    println(data(minbuffer))
    println(-data(maxbuffer))
    glBindFramebuffer(GL_FRAMEBUFFER, Romeo.RENDER_FRAMEBUFFER)
    glClampColor(GL_CLAMP_VERTEX_COLOR, GL_TRUE)
    glClampColor(GL_CLAMP_READ_COLOR, GL_TRUE)
    glClampColor(GL_CLAMP_FRAGMENT_COLOR, GL_TRUE)
end
end


const testdata = rand(-100f0:100, 79,66)
obj = visualize(testdata)

boundingbox(obj)
println(maximum(testdata))
println(minimum(testdata))

GLFW.Terminate()