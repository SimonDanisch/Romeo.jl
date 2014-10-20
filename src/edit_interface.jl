


edit{T <: AbstractArray}(text::Texture{T, 1, 2}, style=Style(:Default); customization...) = edit(style, text, mergedefault!(style, MATRIX_EDITING_DEFAULTS, customization))