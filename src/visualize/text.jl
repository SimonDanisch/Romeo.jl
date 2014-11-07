#=
The text needs to be uploaded into a 2D texture, with 1D alignement, as there is no way to vary the row length, which would be a big waste of memory.
This is why there is the need, to prepare offsets information about where exactly new lines reside.
If the string doesn't contain a new line, the text is restricted to one line, which is uploaded into one 1D texture.
This is important for differentiation between multi-line and single line text, which might need different treatment
=#
function visualize(style::Style{:Default}, text::String, data::Dict{Symbol, Any})
  glypharray          = toglypharray(text)
  data[:style_group]  = Texture([data[:color]])
  data[:textlength]   = length(text) # needs to get remembered, as glypharray is usually bigger than the text
  data[:lines]        = count(x->x=='\n', text) 
  textGPU             = Texture(glypharray)
  # To make things simple for now, checks if the texture is too big for the GPU are done by 'Texture' and an error gets thrown there.
  return visualize(style, textGPU, data)
end

# This is the low-level text interface, which simply prepares the correct shader and cameras
function visualize(::Style{:Default}, text::Texture{GLGlyph{Uint16}, 4, 2}, data::Dict{Symbol, Any})
  screen             = data[:screen]
  camera             = screen.orthographiccam
  renderdata         = merge(data, data[:font].data) # merge font texture and uv informations -> details @ GLFont/src/types.jl
  renderdata[:model] = renderdata[:model] * translationmatrix(Vec3(20,screen.area.value.y,0))

  view = @compat Dict(
    "GLSL_EXTENSIONS" => "#extension GL_ARB_draw_instanced : enable"
  )
  renderdata[:text]           = text
  renderdata[:projectionview] = camera.projectionview
  shader = TemplateProgram(
    Pkg.dir("GLText", "src", "textShader.vert"), Pkg.dir("GLText", "src", "textShader.frag"), 
    view=view, attributes=renderdata, fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")]
  )
  obj = instancedobject(renderdata, shader, data[:textlength])
  prerender!(obj, enabletransparency, glDisable, GL_DEPTH_TEST, glDisable, GL_CULL_FACE,)
  return obj
end