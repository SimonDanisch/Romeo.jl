
function edit(style::Style, obj::RenderObject, customization::Dict{Symbol,Any})
  screen         = customization[:screen]

  yposition      = lift(x->x.h, screen.area)
  glypharray     = GLGlyph{Uint16}()
  visualizations = RenderObjct[]

  for (name,value) in obj.uniforms
    glypharray = [glypharray, [GLGlyph(c, yposition.value, k, 0) for (c,k) in enumerate(string(name))]]
    visual, signal = edit(value, style)
    visual.boundinbbox(visual)
    
    obj.uniforms[name] = signal
    push!(visualizations, visual)
  end

end
