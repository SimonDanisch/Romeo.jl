using ImmutableArrays
function scalematrix{T}(scale::Vector3{T})
    result      = eye(T, 4, 4)
    result[1,1] = scale[1]
    result[2,2] = scale[2]
    result[3,3] = scale[3]

    return Matrix4x4(result)
end
immutable AABB{T}
  min::Vector3{T}
  max::Vector3{T}
end
function Base.max{T, NDIM}(x::Array{Vector3{T},NDIM})
    reduce(x) do v0, v1
        Vector3(v0[1] > v1[1] ? v0[1] : v1[1],
            v0[2] > v1[2] ? v0[2] : v1[2],
            v0[3] > v1[3] ? v0[3] : v1[3])
    end
end

function maxper(v0::Vector3, v1::Vector3)
	return Vector3(max(v0[1], v1[1]),
            max(v0[2], v1[2]),
            max(v0[3], v1[3]))
end
function minper(v0::Vector3, v1::Vector3)
	return Vector3(min(v0[1], v1[1]),
            min(v0[2], v1[2]),
            min(v0[3], v1[3]))
end

function Base.min{T, NDIM}(x::Array{Vector3{T},NDIM}) = reduce(minper, x)
function Base.max{T, NDIM}(x::Array{Vector3{T},NDIM}) = reduce(maxper, x)
    
function Base.min{T, NDIM}(x::Array{Vector4{T},NDIM})
    reduce(x) do v0, v1
        Vector4(v0[1] < v1[1] ? v0[1] : v1[1],
            v0[2] < v1[2] ? v0[2] : v1[2],
            v0[3] < v1[3] ? v0[3] : v1[3],
            v0[4] < v1[4] ? v0[4] : v1[4])
    end
end
const Vec3 = Vector3{Float32}
const Vec2 = Vector2{Float32}
const Vec4 = Vector4{Float32}
const Mat4 = Matrix4x4{Float32}
function genquad{T}(downleft::Vector3{T}, width::Vector3{T}, height::Vector3{T})
    v = Vector3{T}[
        downleft,
        downleft + height,
        downleft + width + height,
        downleft + width 
    ]
    uv = Vector2{T}[
        Vector2{T}(0, 1),
        Vector2{T}(0, 0),
        Vector2{T}(1, 0),
        Vector2{T}(1, 1)
    ]
    indexes = Uint32[0,1,2,2,3,0]

    normal = unit(cross(width, height))
    (v, uv, Vector3{T}[normal for i=1:4], indexes)
end

COLOR_QUAD = genquad(Vec3(0, 0, 0), Vec3(1, 0, 0), Vec3(0, 1, 0))
color = Dict(
  :middle                   => Vec2(0.5, 0.5),

  :swatchsize               => 0.1f0,
  :border_size              => 0.02f0,

  :antialiasing_value       => 0.01f0,
  :model                    => scalematrix(Vec3(200,200,1))
  )
function color_chooser_boundingbox(obj)
  middle      = obj[:middle]  
  swatchsize  = obj[:swatchsize]
  border_size = obj[:border_size]
  model       = obj[:model]
  verts       = COLOR_QUAD[1]
  verts = map(verts) do x
    Vec3(model*Vec4(x...,0f0))
  end
  AABB(min(verts), max(verts))
end



abstract AbstractFixedVector{T,C}
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

Base.start{T}(::GLGlyph{T})                    = 1
Base.next{T}(x::GLGlyph{T}, state::Integer)    = (getfield(x, state), state+1)
Base.done{T}(x::GLGlyph{T}, state::Integer)    = state > 4

function setindex1D!{T <: AbstractFixedVector, ElType}(a::Union(Matrix{T}, Vector{T}), x::ElType, i::Integer, accessor::Integer)
    if length(a) < i
        error("Out of Bounds. 1D index: ", i, " Matrix: ", typeof(a), " length: ", length(a), " size: ", size(a))
    end
    cardinality = length(T)
    if length(accessor) > cardinality
        error("Out of Bounds. 1D index: ", i, " Matrix: ", typeof(a), " length: ", length(a), " size: ", size(a))
    end

  ptr = convert(Ptr{eltype(T)}, pointer(a))
  unsafe_store!(ptr, convert(eltype(T), x), ((i-1)*cardinality)+accessor)
end
function setindex1D!{T <: AbstractFixedVector, ElType}(a::Union(Matrix{T}, Vector{T}), x::Vector{ElType}, i::Integer, accessor::UnitRange)
   if length(a) < i
     error("Out of Bounds. 1D index: ", i, " Matrix: ", typeof(a), " length: ", length(a), " size: ", size(a))
   end
   cardinality = length(T)
   if length(accessor) > cardinality
     error("Out of Bounds. 1D index: ", i, " Matrix: ", typeof(a), " length: ", length(a), " size: ", size(a))
   end
   eltp  = eltype(T)
   x     = convert(Vector{eltp}, x)
   ptr   = convert(Ptr{eltp}, pointer(a))
   unsafe_copy!(ptr + (sizeof(eltp)*((i-1)*(cardinality)+first(accessor-1))), pointer(x), length(accessor))
end

import Base: (+)

function (+){T}(a::Array{GLGlyph{T}, 1}, b::GLGlyph{T})
  for i=1:length(a)
    a[i] = a[i] + b
  end
end
function (+){T}(a::GLGlyph{T}, b::GLGlyph{T})
  GLGlyph{T}(a.glyph + b.glyph, a.line + b.line, a.row + b.row, a.style_group + b.style_group)
end
Base.utf16(glypharray::Array{GLGlyph{Uint16}}) = utf16(Uint16[c.glyph for c in glypharray])
Base.utf8(glypharray::Array{GLGlyph{Uint16}})  = utf8(Uint8[uint8(c.glyph) for c in glypharray])

function escape_regex(x::String)
  result = ""
  for elem in x
      if elem in regex_literals
          result *= string('\\')
      end
      result *= string(elem)
  end
  result
end
regreduce(arr, prefix="(", suffix=")") = Regex(reduce((v0, x) -> v0*"|"*prefix*escape_regex(x)*suffix, prefix*escape_regex(arr[1])*suffix, arr[2:end]))




function update_glyphpositions!{T}(text_array::AbstractArray{GLGlyph{T}}, start=1, stop=length(text_array))
  line = text_array[start].line
  row  = text_array[start].row
  for i=1:stop
    glyph = text_array[i].glyph
    setindex1D!(text_array, T[line, row], i, 2:3)
    if glyph == '\n'
      row = zero(T)
      line += one(T)
    else
      row += one(T)
    end
  end
end

function makedisplayable(text::String)
  result = map(collect(text)) do x
    str = string(x)
    if !is_valid_utf8(str)
      return utf8([one(Uint8)]) # replace with something that yields a missing symbol
    elseif str == "\r"
      return "\n"
    else
      return str == "\t" ? utf8(" "^tab) : utf8(str) # also replace tabs
    end
  end
  join(result)
end 

function toglypharray(text::String, tab=3)
  #@assert is_valid_utf16(text) # future support for utf16
  text = makedisplayable(text)
  #Allocate some more memory, to reduce growing the texture residing on VRAM
  texturesize = div(length(text),     1024)+1 # a texture size of 1024 should be supported on every GPU
  text_array  = Array(GLGlyph{Uint16}, 1024, texturesize)
  setindex1D!(text_array, 1, 1, 2) # set first line
  setindex1D!(text_array, 0, 1, 3) # set first row
  #Set text
  for (i, elem) in enumerate(text)
    setindex1D!(text_array, uint16(char(elem)), i, 1)
    setindex1D!(text_array, 0, i, 4)
  end
  update_glyphpositions!(text_array) # calculate glyph positions
  text_array
end

text = Dict(
  :scalingfactor    => Vec2(1.0, 1.5), #Multiplicator for advance, newline
  :model            => eye(Mat4),
  :newline          => -Vec3(0, 24, 0),
  :advance          => Vec3(12, 0, 0),
  :text 			=> toglypharray("alkjsdölkjdsöfljk\n"^15),
  :textlength 		=> length("alkjsdölkjdsöfljk\n"^15)
)

function text_boundingbox(obj)
  glypharray  = obj[:text]  
  advance  	  = obj[:advance]  
  newline  	  = obj[:newline]  

  maxv = Vector3(typemin(Float32))
  minv = Vector3(typemax(Float32))
  for elem in glypharray[1:obj[:textlength]]
  	println(elem.row)
  	currentpos = elem.row*advance + elem.line*newline
  	maxv = maxper(maxv, currentpos)
  	minv = minper(minv, currentpos)
  end
  AABB(minv, maxv)
end

println(text_boundingbox(text))