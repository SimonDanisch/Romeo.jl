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

maxbuffer = genrenderbuffer(GL_RGBA32F, framebuffsize, GL_COLOR_ATTACHMENT0)
minbuffer = genrenderbuffer(GL_RGBA32F, framebuffsize, GL_COLOR_ATTACHMENT1)
glBindFramebuffer(GL_FRAMEBUFFER, Romeo.RENDER_FRAMEBUFFER)




function lollyy{T, ColorDim, NDim}(t::Texture{T, ColorDim, NDim})
	result = Array(T, t.dims...)
    glBindTexture(t.texturetype, t.id)
    glGetTexImage(t.texturetype, 0, t.format, t.pixeltype, result)
    return result
end
glClearColor(0,0,0,0)
function boundingbox(renderobject)
	glBindFramebuffer(GL_FRAMEBUFFER, BOUNDINGBOX_FRAMEBUFFER)
	glViewport(0,0, framebuffsize...)
	glClear(GL_COLOR_BUFFER_BIT)

	glDisable(GL_DEPTH_TEST)
	glDisable(GL_CULL_FACE)
	#glEnable(GL_BLEND)
	#glBlendFunc(GL_ONE, GL_ONE)
	#glBlendEquation(GL_MIN)

    program = renderobject.vertexarraybb.program
    glUseProgram(program.id)
    for (key,value) in program.uniformloc 
        gluniform(value..., renderobject.uniforms[key])
    end
    glBindVertexArray(renderobject.vertexarraybb.id)

    glDrawElementsInstanced(GL_POINTS, renderobject.vertexarraybb.indexlength, GL_UNSIGNED_INT, C_NULL, renderobject[:postrender, renderinstanced][2])

    glReadBuffer(GL_COLOR_ATTACHMENT0)
    data = Vec3[Vec3(0.0)]
    glReadPixels(0,0,framebuffsize..., GL_RGBA, GL_FLOAT, data)
    println(data)
    glReadBuffer(GL_COLOR_ATTACHMENT1)
    glReadPixels(0,0,framebuffsize..., GL_RGBA, GL_FLOAT, data)
    println(data)

	glBindFramebuffer(GL_FRAMEBUFFER, Romeo.RENDER_FRAMEBUFFER)

end
end

test = rand(Float32, 50,60)
obj2 = visualize(test)

println(maximum(test))
println(minimum(test))

println(obj2[:x])
println(obj2[:y])

boundingbox(obj2)
GLFW.Terminate()