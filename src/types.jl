#=
Style Type, which is used to choose different visualization/editing styles via multiple dispatch
Usage pattern:
visualize(::Style{:Default}, ...)           = do something
visualize(::Style{:MyAwesomeNewStyle}, ...) = do something different
=#
immutable Style{StyleValue}
end
Style(x::Symbol) = Style{x}()
mergedefault!{S}(style::Style{S}, styles, customdata) = merge!(styles[S], Dict{Symbol, Any}(customdata))

#########################################################################################################
#=
Glyph type for Text rendering.
It doesn't offer any functionality, and is only used for multiple dispatch.
=#
immutable GLGlyph{T} <: AbstractFixedVector{T, 4}
  glyph::T
  line::T
  row::T
  style_group::T
end

function GLGlyph(glyph::Integer, line::Integer, row::Integer, style_group::Integer)
  if !isascii(char(glyph))
    glyph = char('1')
  end
  GLGlyph{Uint16}(uint16(glyph), uint16(line), uint16(row), uint16(style_group))
end
function GLGlyph(glyph::Char, line::Integer, row::Integer, style_group::Integer)
  if !isascii(glyph)
    glyph = char('1')
  end
  GLGlyph{Uint16}(uint16(glyph), uint16(line), uint16(row), uint16(style_group))
end

GLGlyph() = GLGlyph(' ', typemax(Uint16), typemax(Uint16), 0)

Base.length{T}(::GLGlyph{T})                   = 4
Base.length{T}(::Type{GLGlyph{T}})             = 4
Base.eltype{T}(::GLGlyph{T})                   = T
Base.eltype{T}(::Type{GLGlyph{T}})             = T
Base.size{T}(::GLGlyph{T})                     = (4,)

import Base: (+)

function (+){T}(a::Array{GLGlyph{T}, 1}, b::GLGlyph{T})
  for i=1:length(a)
    a[i] = a[i] + b
  end
end
function (+){T}(a::GLGlyph{T}, b::GLGlyph{T})
  GLGlyph{T}(a.glyph + b.glyph, a.line + b.line, a.row + b.row, a.style_group + b.style_group)
end
#########################################################################################################

