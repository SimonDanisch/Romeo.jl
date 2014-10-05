function createdisplay()
  windowhints = [
    (GLFW.SAMPLES, 0), 
    (GLFW.DEPTH_BITS, 0), 
    (GLFW.ALPHA_BITS, 0), 
    (GLFW.STENCIL_BITS, 0),
    (GLFW.AUX_BUFFERS, 0)
  ]

  window  = createdisplay(w=1920, h=1080, windowhints=windowhints)

  mousepos = window.inputs[:mouseposition]

  color_mousepos = lift(mousepos) do xy 
    if isinside(Rectangle(0f0,0f0,200f0,200f0), xy[1], xy[2])
      return Vec2(xy...)
    else
      Vec2(-1f0)
    end
  end

  mousepos_cam = lift(mousepos) do xy 
    if !isinside(Rectangle(0f0,0f0,200f0,200f0), xy[1], xy[2])
      return xy
    else
      Vector2(0.0)
    end
  end

  parameters = [
          (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
          (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE ),

          (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
          (GL_TEXTURE_MAG_FILTER, GL_NEAREST) 
  ]

  fb = glGenFramebuffers()
  glBindFramebuffer(GL_FRAMEBUFFER, fb)

  framebuffsize = [window.inputs[:framebuffer_size].value]

  color     = Texture(RGBA{Ufixed8},     framebuffsize, parameters=parameters)
  stencil   = Texture(Vector2{GLushort}, framebuffsize, parameters=parameters)

  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, color.id, 0)
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, stencil.id, 0)

  rboDepthStencil = GLuint[0]

  glGenRenderbuffers(1, rboDepthStencil)
  glBindRenderbuffer(GL_RENDERBUFFER, rboDepthStencil[1])
  glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, framebuffsize...)
  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rboDepthStencil[1])

  lift(window.inputs[:framebuffer_size]) do window_size
    resize!(color, window_size)
    resize!(stencil, window_size)
    glBindRenderbuffer(GL_RENDERBUFFER, rboDepthStencil[1])
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, window_size...)
  end
end

function renderloop(window)
  global RENDER_LIST
  glClearColor(1,1,1,0)
  while !GLFW.WindowShouldClose(window.glfwWindow)
    yield() 
    glBindFramebuffer(GL_FRAMEBUFFER, fb)
    glDrawBuffers(2, [GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1])
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    for elem in RENDER_LIST
       render(elem)
    end

    mousex, mousey = int([color_mousepos.value])
    if mousex > 0 && mousey > 0
      glReadBuffer(GL_COLOR_ATTACHMENT1) 
      glReadPixels(mousex, mousey, 1,1, stencil.format, stencil.pixeltype, mousehover)
      @async push!(selectiondata, mousehover)
    end

    glReadBuffer(GL_COLOR_ATTACHMENT0)
    glBindFramebuffer(GL_READ_FRAMEBUFFER, fb)
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0)
    glClear(GL_COLOR_BUFFER_BIT)

    window_size = window.inputs[:framebuffer_size].value
    glBlitFramebuffer(0,0, window_size..., 0,0, window_size..., GL_COLOR_BUFFER_BIT, GL_NEAREST)
      
    GLFW.SwapBuffers(window.glfwWindow)
    GLFW.PollEvents()
  end
  GLFW.Terminate()
  empty!(RENDER_LIST)
end