begin 
local color_chooser_shader = TemplateProgram(
  joinpath(shaderdir, "colorchooser.vert"), joinpath(shaderdir, "colorchooser.frag"), 
  fragdatalocation=[(0, "fragment_color"), (1, "fragment_groupid")]
)

local quad = genquad(Vec3(0, 0, 0), Vec3(50, 0, 0), Vec3(0, 50, 0))

#GLPlot.toopengl{T <: AbstractRGB}(colorinput::Input{T}) = toopengl(lift(x->AlphaColorValue(x, one(T)), RGBA{T}, colorinput))

function visualize{X <: AbstractAlphaColorValue}(style::Style, color::X, data)
  screen       = data[:screen]
  camera       = screen.orthographiccam

  rdata = merge(@compat(Dict(
    :vertex => GLBuffer(quad[1]),
    :uv     => GLBuffer(quad[2]),
    :index  => indexbuffer(quad[4]),
  )), data)

  rdata[:view]       = camera.view
  rdata[:projection] = camera.projection
  rdata[:color]      = color

  obj = RenderObject(rdata, color_chooser_shader)

  prerender!(obj, glDisable, GL_CULL_FACE, glDisable, GL_DEPTH_TEST)#
  postrender!(obj, render, obj.vertexarray) # Render the vertexarray

  obj
end
end # local begin color chooser