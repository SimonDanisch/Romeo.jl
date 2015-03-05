# --line 3572 --  -- from : "BigData.pamphlet"  
# This module is just a placeholder for Version 0.4 Base/doc.jl
# therefore, in older version it silently swallows the @doc <string> -> syntax
# attempting to do no harm... (remains to be checked). In later versions it just
# loads Base/doc.j

# This code is (vaguely) inspired by base/docs.jl
#

module ALDoc

export doc, @doc

using Base.Meta

macro doc_str(x)
    print(x)
    end

# Modules
const modules = Module[]
# Keywords
const keywords = Dict{Symbol,Any}()


function objdoc(meta, def)
    quote
        f = $(esc(def))
        f
    end
end

function docm(meta, def)
    return objdoc(meta, def)
end

function docm(ex)
    isexpr(ex, :->) && return docm(ex.args...)
    isexpr(ex, :call) && return :(doc($(esc(ex.args[1])), @which $(esc(ex))))
    isexpr(ex, :macrocall) && (ex = namify(ex))
    :(doc($(esc(ex))))
end

macro doc (args...)
    docm(args...)
end


end # module ALDoc

if isless(VersionNumber(0,4),VERSION)
    using Base.doc
else
    using ALDoc
end
