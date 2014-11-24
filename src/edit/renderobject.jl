

function edit(style::Style, obj::RenderObject, customization::Dict{Symbol,Any})
  screen         = customization[:screen]

  yposition      = float32(screen.area.value.h)

  glypharray     = Array(GLGlyph{Uint16}, 0)
  visualizations = RenderObject[]
  xgap = 20f0
  ygap = 20f0
  lineheight = 24f0
  for (name,value) in obj.uniforms
    try
      visual, signal     = edit(value, style, screen=screen)
      append!(glypharray, GLGlyph{Uint16}[GLGlyph(c, int(yposition/24), k, 0) for (k,c) in enumerate(string(name))])
      yposition          -= lineheight
      aabb               = visual.boundingbox(visual)
      println(name, ": ", aabb.min[2])
      translatm          = translationmatrix(Vec3(xgap,yposition,0))
      yposition          += aabb.min[2] - ygap

      visual[:model]     = visual[:model] * translatm
      obj.uniforms[name] = signal
      push!(visualizations, visual)
    catch e
    end
  end
  labels = visualize(glypharray, screen=screen)
  push!(visualizations, labels)
  visualizations
end
