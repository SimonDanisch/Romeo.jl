const global volumeshader = TemplateProgram(joinpath(shaderdir, "simple.vert")     , joinpath(shaderdir, "iso.frag"), fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")])
const global uvwshader    = TemplateProgram(joinpath(shaderdir, "uvwposition.vert"), joinpath(shaderdir, "uvwposition.frag"))
const global uvwposition_framebuffer = glGenFramebuffers() 


function visualize{T,A}(style::Style, img::Image{T, 3, A}, data::Dict{Symbol, Any})
  volume = img.data
  max = maximum(volume)
  min = minimum(volume)
  volume = float32((volume .- min) ./ (max - min))
  spacing = get(img.properties, "spacing", [1f0, 1f0, 1f0])
  
  toopengl(volume, stepsize=stepsize, isovalue=isovalue, algorithm=algorithm, color=color)
end

begin 
  local texparams = [
      (GL_TEXTURE_MIN_FILTER, GL_LINEAR),
      (GL_TEXTURE_MAG_FILTER, GL_LINEAR),
      (GL_TEXTURE_WRAP_S,     GL_CLAMP_TO_EDGE),
      (GL_TEXTURE_WRAP_T,     GL_CLAMP_TO_EDGE),
      (GL_TEXTURE_WRAP_R,     GL_CLAMP_TO_EDGE)
  ]
  function visualize{T <: Real}(style::Style, img::Array{T, 3}, data::Dict{Symbol, Any})
    spacing = data[:spacing]
    camera = data[:camera]

    v, uvw, indexes = gencube(data[:spacing]...)

    cube1,frontf1, backf1 = genuvwcube(1f0, 1f0, 1f0, uvwposition_framebuffer, camera)
    cube2,frontf2, backf2 = genuvwcube(0.1f0, 1f0, 1f0, uvwposition_framebuffer, camera)

    data[:vertex]         = GLBuffer(v, 3)
    data[:indexes]        = indexbuffer(indexes)
    data[:projectionview] = camera.projectionview
    data[:frontface1]     = frontf1
    data[:backface1]      = backf1
    data[:backface2]      = backf2
    data[:frontface2]     = frontf2
    data[:volume_tex]     = Texture(img, parameters=texparams)

    volume = RenderObject(data, volumeshader)

    rendertouvwtexture = () -> begin
      render(cube1)
      render(cube2)
      glBindFramebuffer(GL_FRAMEBUFFER, RENDER_FRAMEBUFFER)

    end
    prerender!(volume, rendertouvwtexture, glEnable, GL_DEPTH_TEST, glDepthFunc, GL_LESS, glEnable, GL_CULL_FACE, glCullFace, GL_BACK, enabletransparency)
    postrender!(volume, render, volume.vertexarray)
    volume
  end
end
#=
function toopengl(dirpath::String; stepsize=0.001f0, isovalue=0.5f0, algorithm=2f0, color=Vec4(0,0,1,1))
  files     = readdir(dirpath)
  imgSlice1 = imread(dirpath*files[1])
  volume    = Array(Uint16, size(imgSlice1,1), size(imgSlice1,2), length(files))
  imgSlice1 = 0
  for (i,elem) in enumerate(files)
    img = imread(dirpath*elem)
    volume[:,:, i] = img.data
  end
  max = maximum(volume)
  min = minimum(volume)

  volume = float32((volume .- min) ./ (max - min))
  volume = volume
  toopengl(volume, stepsize=stepsize, isovalue=isovalue, algorithm=algorithm, color=color)
end
=#

function genuvwcube(x, y, z, fb, camera)
  v, uvw, indexes = gencube(x,y,z)
  cubeobj = RenderObject([
    :vertex         => GLBuffer(v, 3),
    :uvw            => GLBuffer(uvw, 3),
    :indexes        => indexbuffer(indexes),
    :projectionview => camera.projectionview
  ], uvwshader)

  frontface = Texture(Vec4, window.inputs[:window_size].value[3:4])
  backface  = Texture(Vec4, window.inputs[:window_size].value[3:4])

  lift(window.inputs[:window_size]) do window_size
    resize!(frontface, window_size[3:4])
    resize!(backface, window_size[3:4])
  end
  
  rendersetup = () -> begin
      glBindFramebuffer(GL_FRAMEBUFFER, fb)
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, backface.id, 0)
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

      glDisable(GL_DEPTH_TEST)
      glEnable(GL_CULL_FACE)
      glCullFace(GL_FRONT)
      render(cubeobj.vertexarray)

      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, frontface.id, 0)
      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

      glDisable(GL_DEPTH_TEST)
      glEnable(GL_CULL_FACE)
      glCullFace(GL_BACK)
      render(cubeobj.vertexarray)

  end

  postrender!(cubeobj, rendersetup)

  cubeobj, frontface, backface
end

