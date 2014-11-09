using GLWindow, ModernGL, GLAbstraction, Romeo, Color, Images
function genrenderbuffer(format, dimensions, attachment)
    renderbuffer = GLuint[0]
    glGenRenderbuffers(1, renderbuffer)
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer[1])
    glRenderbufferStorage(GL_RENDERBUFFER, format, dimensions...)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, attachment, GL_RENDERBUFFER, renderbuffer[1])
    renderbuffer[1]
end
begin
local const BOUNDINGBOX_FRAMEBUFFER = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, BOUNDINGBOX_FRAMEBUFFER)
framebuffsize = [1,1]

maxbuffer = genrenderbuffer(GL_RGB32F, framebuffsize, GL_COLOR_ATTACHMENT0)
minbuffer = genrenderbuffer(GL_RGB32F, framebuffsize, GL_COLOR_ATTACHMENT1)
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

function boundingbox(renderobject)
    glClampColor(GL_CLAMP_VERTEX_COLOR, GL_FALSE);
    glClampColor(GL_CLAMP_READ_COLOR, GL_FALSE);
    glClampColor(GL_CLAMP_FRAGMENT_COLOR, GL_FALSE);
    glBindFramebuffer(GL_FRAMEBUFFER, BOUNDINGBOX_FRAMEBUFFER)
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
    glViewport(0,0, framebuffsize...)
    glClear(GL_COLOR_BUFFER_BIT)

    glDisable(GL_DEPTH_TEST)
    glDisable(GL_CULL_FACE)
    glEnable(GL_BLEND)
    glBlendFunc(GL_ONE, GL_ONE)
    glBlendEquation(GL_MAX)

    program = renderobject.vertexarraybb.program
    glUseProgram(program.id)
    glBindVertexArray(renderobject.vertexarraybb.id)
    glDrawElements(GL_POINTS, renderobject.vertexarraybb.indexlength, GL_UNSIGNED_INT, GL_NONE)

    glReadBuffer(GL_COLOR_ATTACHMENT0)
    data = Array(Vec3, framebuffsize...)
    glReadPixels(0,0,framebuffsize..., GL_RGB, GL_FLOAT, data)
    println(data)
    glReadBuffer(GL_COLOR_ATTACHMENT1)
    glReadPixels(0,0,framebuffsize..., GL_RGB, GL_FLOAT, data)
    println(data)

    glBindFramebuffer(GL_FRAMEBUFFER, Romeo.RENDER_FRAMEBUFFER)

end
end


shaderdir = Pkg.dir("Romeo", "src", "shader")
homedir = Pkg.dir("Romeo", "src", "boundingbox")

bbprogram = TemplateProgram(joinpath(homedir, "shader.vert"), joinpath(shaderdir,"boundingbox", "boundingbox.frag"),fragdatalocation=[(0, "minbuffer"),(1, "maxbuffer")])

indexes = indexbuffer(GLuint[0,1,2])
v = Float32[0.0,0.9,0.0,
            2.0,-33,-0.29218,
            0.66,-0.9, 0.34]

const triangle = RenderObject(Dict(
        :vertex => GLBuffer(v, 3),
        :index => indexes
    ),
    bbprogram, bbprogram)

postrender!(triangle, render, triangle.vertexarray)

boundingbox(triangle)

#=
glClearColor(0,0,0,0)
while Romeo.ROOT_SCREEN.inputs[:open].value
    glBindFramebuffer(GL_FRAMEBUFFER, 0)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glViewport(0,0, 1920, 1280)
    render(triangle)
    GLFW.SwapBuffers(Romeo.ROOT_SCREEN.nativewindow)
    GLFW.PollEvents()
    sleep(0.01)
end
=#
GLFW.Terminate()
