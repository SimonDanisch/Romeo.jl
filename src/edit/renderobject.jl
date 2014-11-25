

function edit(style::Style, obj::RenderObject, customization::Dict{Symbol,Any})
  screen         = customization[:screen]

  yposition      = float32(screen.area.value.h)

  glypharray     = Array(Romeo.GLGlyph{Uint16}, 0)
  visualizations = RenderObject[]
  xgap = 60f0
  ygap = 20f0
  lineheight = 24f0
  currentline = 0
  aabb = AABB(Vec3(0), Vec3(0))
  i = 0
  for (name,value) in obj.uniforms
    if method_exists(edit, (typeof(value),))
        currentline       += int(abs(aabb.min[2])/lineheight) + i
        yposition         -= lineheight*2
        i = 3
        append!(glypharray, Romeo.GLGlyph{Uint16}[Romeo.GLGlyph(c, currentline, k, 0) for (k,c) in enumerate(string(name))])
        visual, signal     = Romeo.edit(value, style, screen=screen)
        translatm          = translationmatrix(Vec3(xgap, yposition,0))
        visual[:model]     = translatm * visual[:model]
        obj.uniforms[name] = signal

        aabb               = visual.boundingbox(visual)
        yposition          += aabb.min[2] - lineheight
        push!(visualizations, visual)
    end
  end
  labels = visualize(glypharray, screen=screen, model=translationmatrix(Vec3(30, float32(screen.area.value.h), 0)))
  push!(visualizations, labels)
  visualizations
end
