#################################################################################################################################
#Text Rendering:
TEXT_DEFAULTS = @compat Dict(
:Default => @compat Dict(
  :start            => Vec3(0),
  :offset           => Vec2(1, 1.5), #Multiplicator for advance, newline
  :color            => rgbaU8(248.0/255.0, 248.0/255.0,242.0/255.0, 1.0),
  :backgroundcolor  => rgbaU8(0,0,0,0),
  :model            => eye(Mat4),
  :newline          => -Vec3(0, getfont().props[1][2], 0),
  :advance          => Vec3(getfont().props[1][1], 0, 0),
  :camera           => pocamera,
  :font             => getfont()
))

# High Level text rendering for one line or multi line text, which is decided by searching for the occurence of '\n' in text
visualize(text::String, style=Style(:Default); customization...) = visualize(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))
# Low level text rendering for multiple line text
visualize{T}(text::Texture{GLGlyph{T}, 4, 2}, style=Style(:Default); customization...) = visualize(style, text, mergedefault!(style, TEXT_DEFAULTS, customization))

# END Text Rendering
#################################################################################################################################