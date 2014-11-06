TEXT_EDIT_DEFAULTS = @compat Dict{Symbol, Any}(
:Default => @compat Dict{Symbol, Any}(
	:model           => eye(Mat4),
	:screen          => ROOT_SCREEN

))
edit(text::Texture{GLGlyph{Uint16}, 4, 2}, obj, style=Style(:Default); customization...) = edit(style, text, mergedefault!(style, TEXT_EDIT_DEFAULTS, customization))




MATRIX_EDITING_DEFAULTS = @compat(Dict(
:Default => @compat(Dict(
	:offset          => Vec2(1.5, 1.5), #Multiplicator for advance, newline
	:backgroundcolor => rgba(0.9, 0.9, 0.9, 1.0),
	:color           => rgba(0,0,0,1),
	:maxdigits       => 5f0,
	:maxlength       => 10f0, 
	:model           => eye(Mat4),
	:screen          => ROOT_SCREEN,
	:font            => getfont(),
	:newline          => -Vec3(0, getfont().props[1][2], 0),
	:advance          => Vec3(getfont().props[1][1], 0, 0)
))
))
# High Level text rendering for one line or multi line text, which is decided by searching for the occurence of '\n' in text
# Low level text rendering for one line text
# Low level text rendering for multiple line text
edit{T <: Union(AbstractFixedVector, Real)}(text::Texture{T, 1, 2}, style=Style(:Default); customization...) = edit(style, text, mergedefault!(style, MATRIX_EDITING_DEFAULTS, customization))
