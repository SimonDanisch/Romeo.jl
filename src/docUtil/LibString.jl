module LibString

export elide

function elide{T <: AbstractString}(s::T, len::Int)
    l = length(s)
    if l > len 
      return s[1:len]
    else
      return s
    end
end

function elide{T <: AbstractString, S<:AbstractString}(s::T, len::Int, termin::S)
    l = length(s)
    if l > len -length(termin)
      return s[1:len]*termin
    else
      return s
    end
end


end  # module LibString

