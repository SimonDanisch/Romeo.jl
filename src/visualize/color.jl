begin 
local color_chooser_shader = TemplateProgram(joinpath(shaderdir, "colorchooser.vert"), joinpath(shaderdir, "colorchooser.frag"), 
  fragdatalocation=[(0, "fragment_color"),(1, "fragment_groupid")])
local quad = genquad(Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0))

local data = [

:vertex                   => GLBuffer(quad[1]),
:uv                       => GLBuffer(quad[2]),
:index                    => indexbuffer(quad[4]),

:middle                   => Vec2(0.5),
:color                    => rgba(0,1,0,1),

:swatchsize               => 0.1f0,
:border_color             => rgba(1, 1, 0.99, 1),
:border_size              => 0.01f0,

:hover                    => Input(false),
:hue_saturation           => Input(false),
:brightness_transparency  => Input(false),

:antialiasing_value       => 0.01f0,
]

#GLPlot.toopengl{T <: AbstractRGB}(colorinput::Input{T}) = toopengl(lift(x->AlphaColorValue(x, one(T)), RGBA{T}, colorinput))

function visualize{X <: AbstractAlphaColorValue}(colorinput::Signal{X}; camera=ocam)

  data[:view]       = camera.view
  data[:projection] = camera.projection
  data[:model]      = eye(Mat4)

  obj = RenderObject(data, color_chooser_shader)
  obj[:postrender, render] = (obj.vertexarray,) # Render the vertexarray

  color = colorinput.value

  # hover is true, if mouse 
  hover = lift(selectiondata) do selection
    selection[1][1] == obj.id
  end


  all_signals = foldl((tohsv(color), false, false, Vec2(0)), selectiondata) do v0, selection

    hsv, hue_sat0, bright_trans0, mouse0 = v0
    mouse           = window.inputs[:mouseposition].value
    mouse_clicked   = window.inputs[:mousebuttonspressed].value

    hue_sat = in(0, mouse_clicked) && selection[1][1] == obj.id
    bright_trans = in(1, mouse_clicked) && selection[1][1] == obj.id
    

    if hue_sat && hue_sat0
      diff = mouse - mouse0
      hue = mod(hsv.c.h + diff[1], 360)
      sat = max(min(hsv.c.s + (diff[2] / 30.0), 1.0), 0.0)

      return (tohsv(hue, sat, hsv.c.v, hsv.alpha), hue_sat, bright_trans, mouse)
    elseif hue_sat && !hue_sat0
      return (hsv, hue_sat, bright_trans, mouse)
    end

    if bright_trans && bright_trans0
      diff    = mouse - mouse0
      brightness  = max(min(hsv.c.v - (diff[2]/100.0), 1.0), 0.0)
      alpha     = max(min(hsv.alpha + (diff[1]/100.0), 1.0), 0.0)

      return (tohsv(hsv.c.h, hsv.c.s, brightness, alpha), hue_sat0, bright_trans, mouse)
    elseif bright_trans && !bright_trans0
      return (hsv, hue_sat0, bright_trans, mouse)
    end

    return (hsv, hue_sat, bright_trans, mouse)
  end
  color1 = lift(x -> torgb(x[1]), all_signals)
  color1 = lift(x -> Vec4(x.c.r, x.c.g, x.c.b, x.alpha), Vec4, color1)
  hue_saturation = lift(x -> x[2], all_signals)
  brightness_transparency = lift(x -> x[3], all_signals)


  obj.uniforms[:color]                    = color1
  obj.uniforms[:hover]                    = hover
  obj.uniforms[:hue_saturation]           = hue_saturation
  obj.uniforms[:brightness_transparency]  = brightness_transparency

  return obj
end

end # local begin color chooser