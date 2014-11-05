TEXT_EDIT_DEFAULTS = @compat Dict{Symbol, Any}(
:Default => @compat Dict{Symbol, Any}(

))
edit(text::Texture{GLGlyph{Uint16}, 4, 2}, obj, style=Style(:Default); customization...) = edit(style, text, mergedefault!(style, TEXT_EDIT_DEFAULTS, customization))