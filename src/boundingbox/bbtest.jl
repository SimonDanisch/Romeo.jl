using GLWindow, ModernGL, GLAbstraction, Romeo, Color, Images, ImmutableArrays
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

minbuffer = Texture(Vec4, framebuffsize)
maxbuffer = Texture(Vec4, framebuffsize)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, minbuffer.id, 0)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, maxbuffer.id, 0)
println(GLENUM(glCheckFramebufferStatus(GL_FRAMEBUFFER)).name)
glBindFramebuffer(GL_FRAMEBUFFER, Romeo.RENDER_FRAMEBUFFER)


const FLOAT32MIN = -999999999999999999999999f0

function boundingbox(renderobject)
    renderobject.boundingboxfunc(renderobject)
end

function boundingbox(renderobject)
    minbuffer[1:end,1:end] = Vec4[Vec4(FLOAT32MIN) for i=1:framebuffsize[1], j=1:framebuffsize[2]]
    maxbuffer[1:end,1:end] = Vec4[Vec4(FLOAT32MIN) for i=1:framebuffsize[1], j=1:framebuffsize[2]]
    glBindFramebuffer(GL_FRAMEBUFFER, BOUNDINGBOX_FRAMEBUFFER)
    glViewport(0,0, framebuffsize...)
    glClampColor(GL_CLAMP_VERTEX_COLOR, GL_FALSE)
    glClampColor(GL_CLAMP_READ_COLOR, GL_FALSE)
    glClampColor(GL_CLAMP_FRAGMENT_COLOR, GL_FALSE)
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
    glClearColor(FLOAT32MIN, FLOAT32MIN, FLOAT32MIN, 0)
    glClear(GL_COLOR_BUFFER_BIT | GL_COLOR_BUFFER_BIT)

    glDisable(GL_DEPTH_TEST)
    glDisable(GL_CULL_FACE)
    glDisable(GL_ALPHA_TEST)
    glEnable(GL_BLEND)
    glBlendFunc(GL_ONE, GL_ONE)
    glBlendEquation(GL_MIN)

    program = renderobject.vertexarraybb.program
    glUseProgram(program.id)
    glBindVertexArray(renderobject.vertexarraybb.id)
    glDrawElements(GL_POINTS, renderobject.vertexarraybb.indexlength, GL_UNSIGNED_INT, GL_NONE)

    println(data(minbuffer))
    println(-data(maxbuffer))
    glBindFramebuffer(GL_FRAMEBUFFER, Romeo.RENDER_FRAMEBUFFER)
    glClampColor(GL_CLAMP_VERTEX_COLOR, GL_TRUE)
    glClampColor(GL_CLAMP_READ_COLOR, GL_TRUE)
    glClampColor(GL_CLAMP_FRAGMENT_COLOR, GL_TRUE)
end
end


shaderdir = Pkg.dir("Romeo", "src", "shader")
homedir = Pkg.dir("Romeo", "src", "boundingbox")

bbprogram = TemplateProgram(joinpath(homedir, "shader.vert"), joinpath(shaderdir,"boundingbox", "boundingbox.frag"),fragdatalocation=[(0, "minbuffer"),(1, "maxbuffer")])

indexes = indexbuffer(GLuint[i=0:49])
v = Vec3[Vec3(rand(-100f0:100f0), rand(-100f0:100f0), rand(-100f0:100f0))for i=1:50]
println(v)
function Base.max{T, NDIM}(x::Array{Vector3{T},NDIM})
    reduce(x) do v0, v1
        Vector3(v0[1] > v1[1] ? v0[1] : v1[1],
            v0[2] > v1[2] ? v0[2] : v1[2],
            v0[3] > v1[3] ? v0[3] : v1[3])
    end
end
function Base.min{T, NDIM}(x::Array{Vector3{T},NDIM})
    reduce(x) do v0, v1
        Vector3(v0[1] < v1[1] ? v0[1] : v1[1],
            v0[2] < v1[2] ? v0[2] : v1[2],
            v0[3] < v1[3] ? v0[3] : v1[3])
    end
end
const triangle = RenderObject(Dict(
        :vertex => GLBuffer(v),
        :index => indexes
    ),
    bbprogram, bbprogram)

postrender!(triangle, render, triangle.vertexarray)

boundingbox(triangle)
println(min(v))
println(max(v))
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
