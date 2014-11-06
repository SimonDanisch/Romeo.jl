
edit(text::Texture{GLGlyph{Uint16}, 4, 2}, obj::RenderObject, style=Style(:Default); customization...) = edit(style, text, obj, mergedefault!(style, TEXT_EDIT_DEFAULTS, customization))

function filtereselection(v0, selection, buttons)
  if !isempty(buttons) && first(buttons) == 0  # if any button is pressed && its the left button
    selection #return index
  else
    v0
  end
end

function haschanged(v0, selection)
  (v0[2] != selection, selection)
end

function edit(style::Style{:Default}, textGPU::Texture{GLGlyph{Uint16}, 4, 2}, obj::RenderObject, custumization::Dict{Symbol, Any})
  screen = custumization[:screen]
  specialkeys = filteritems(screen.inputs[:buttonspressed], [GLFW.KEY_ENTER, GLFW.KEY_BACKSPACE], IntSet())

  selectiondata = lift(first, SELECTION[:mouse_hover])
  # Filter out the selected index,
  changed = lift(first, foldl(haschanged, (true, selectiondata.value), selectiondata))

  leftclick_selection = foldl(filtereselection, Vector2(-1), keepwhen(changed, Vector2(-1), selectiondata), screen.inputs[:mousebuttonspressed])

  text      = vec(data(textGPU))
  v00       = (obj, obj.alluniforms[:textlength], textGPU, text, leftclick_selection.value, leftclick_selection.value)

  testinput = foldl(edit_text, v00, leftclick_selection, screen.inputs[:unicodeinput], specialkeys)
end

function edit_text(v0, selection1, unicode_keys, special_keys)
  # selection0 tracks, where the carsor is after a new character addition, selection10 tracks the old selection
  obj, textlength, textGPU, text0, selection0, selection10 = v0
  v1 = (obj, textlength, textGPU, text0, selection0, selection1)
  changed = false 
    # to compare it to the newly selected mouse position
  if selection10 != selection1
    v1 = (obj, textlength, textGPU, text0, selection1, selection1)
  elseif !isempty(special_keys) && isempty(unicode_keys)
    if in(GLFW.KEY_BACKSPACE, special_keys)
      text0 = delete!(text0, selection0[2])
      textlength -= 1
      changed = true
      selection = selection0[2] >= 1 ? Vector2(selection0[1], selection0[2] - 1) : Vector2(selection0[1], 0)
      v1 = (obj, textlength, textGPU, text0, selection, selection1)
    elseif in(GLFW.KEY_ENTER, special_keys)
      text0 = addchar(text0, '\n', selection0[2])
      textlength += 1
      changed = true
      v1 = (obj, textlength, textGPU, text0, selection0 + Vector2(0,1), selection1)
    end
  elseif !isempty(unicode_keys) && selection0[1] == obj.id # else unicode input must have occured
    text0 = addchar(text0, first(unicode_keys), selection0[2])
    textlength += 1
    changed = true
    v1 = (obj, textlength, textGPU, text0, selection0 + Vector2(0,1), selection1)
  end
  if changed
      update_glyphpositions!(textGPU)
    
    if textlength > length(text0) || length(text0) % 1024 != 0
      newlength = 1024 - rem(length(text0)+1024, 1024)
      text0     = [text0, Array(GLGlyph{Uint16}, newlength)]
      resize!(textGPU, [1024, div(length(text0),1024)])
    end
    textGPU[1:end, 1:end] = reshape(text0, 1024, div(length(text0),1024))
    obj[:postrender, renderinstanced] = (obj.vertexarray, textlength)
   
  end
  return v1
end


# Filters a signal. If any of the items is in the signal, the signal is returned.
# Otherwise default is returned
function filteritems{T}(a::Signal{T}, items, default::T)
  lift(a) do signal
    if any(item-> in(item, signal), items)
      signal
    else
      default 
    end
  end
end



function Base.delete!(s::Array{GLGlyph{Uint16}, 1}, Index::Integer)
  if Index == 0
    return s
  elseif Index == length(s)
    return s[1:end-1]
  end
  return [s[1:max(Index-1, 0)], s[min(Index+1,length(s)):end]]
end

addchar(s::Array{GLGlyph{Uint16}, 1}, glyph::Char, Index::Integer) = addchar(s, GLGlyph(glyph, 0, 0, 0), int(Index))
function addchar(s::Array{GLGlyph{Uint16}, 1}, glyph::GLGlyph{Uint16}, i::Integer)
  if i == 0
    return [glyph, s]
  elseif i == length(s)
    return [s, glyph]
  elseif i > length(s) || i < 0
    return s
  end
  return [s[1:i], glyph, s[i+1:end]]
end
