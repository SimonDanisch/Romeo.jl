operators = [":", ";","=", "+", "-", "!", "¬", "~", "<", ">","=", "/", "&", "|", "\$", "*"]
brackets  = ["(", ")", "[", "]", "{", "}"]
keywords  = ["for", "end", "while", "if", "elseif", "using", "return", "in", "function", "local", "global", "let", "quote", "begin", "const", "do", "false", "true"]

regex_literals = ['|', '[', ']', '*', '.', '?', '\\', '(', ')', '{', '}', '+', '-', '$']

julia_groups = @compat Dict(
  1 => regreduce(operators) 
  2 => regreduce(brackets)
  3 => regreduce(keywords, "((?<![[:alpha:]])", "(?![[:alpha:]]))")
  4 => r"(#=.*=#)|(#.*[\n\r])" #Comments
  5 => r"(\".*\")|('.*')|((?<!:):[[:alpha:]][[:alpha:]_]*)" #String alike
  6 => r"(?<![[:alpha:]])[[:graph:]]*\(" # functions 
)


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

TextArrayOrTex = Union(AbstractArray{GLGlyph{T}, 2}, Texture{GLGlyph{T}, 4, 2})

function update_groups!{T}(textGPU::Texture{GLGlyph{T}, 4, 2}, regexs::Dict{T, Regex}, start=1, stop=length(text_array))
  textRam = textGPU.data[start:stop]
  text    = utf8(map(textRam) do x
    char(x.glyph)
  end)
  for (group,regex) in regexs
      for match in matchall(regex, text)
        startorigin = match.offset+1
        stoporigin  = match.offset+match.endof
        setindex1D!(textGPU, group, startorigin:stoporigin, 4) # Set group
      end
  end
end

function update_glyphpositions!{T}(text_array::TextArrayOrTex, start=1, stop=length(text_array))
  line = text_array[start].line
  row  = text_array[start].row

  for i=1:stop
    glyph = text_array[i].glyph
    setindex1D!(text_array, T[line, row], i, 2:3)
    if glyph == '\n'
      row = 0
      line += 1
    else
      row += 1
    end
  end
end


function toglypharray(text::String, tab=3)
  @assert is_valid_utf16(text) # future support for utf16
  text = map(collect(text)) do x
    str = string(x)
    if !is_valid_utf8(str)
      return utf8([char(1)]) # replace with something that yields a missing symbol
    else
      return str == "\t" ? utf8(" "^tab) : utf8(str) # also replace tabs
    end
  end

  #Allocate some more memory, to reduce growing the texture residing on VRAM
  texturesize = (div(length(text),     1024) + 1) # a texture size of 1024 should be supported on every GPU
  text_array  = Array(GLGlyph{Uint16}, 1024, texturesize)
  setindex1D!(text_array, 1, 1, 2) # set first line
  setindex1D!(text_array, 0, 1, 3) # set first row
  update_glyphpositions!(text, text_array) # calculate glyph positions

end
