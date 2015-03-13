importall  Base

abstract FixedSizeArray{T, SZ, N}
abstract FixedSizeVector{T, N} <: FixedSizeArray{T, (N,), 1}

getindex{T <: FixedSizeVector}(c::T, i::Int) = c.(i)

# Ugly workaround for not having triangular dispatch:
eltype{T <: FixedSizeVector}(A::Type{T})                = A.types[1]
length{T <: FixedSizeVector}(A::Type{T})                = length(A.types)
ndims{T <: FixedSizeVector}(A::Type{T})                 = 1
size{T <: FixedSizeVector}(A::Type{T})                  = (length(A),)
size{T <: FixedSizeVector}(A::Type{T}, d::Integer)      = (length(A),) # should throw an error!?

abstract Func{Name, N}
stagedfunction map{T <: FixedSizeVector}(f::Func{1}, a::T)
	typename  = symbol("$(a.name.name)")
	arguments = [:(f(a.($i))) for i=1:length(T)]
    :($typename($(arguments...)))
end

stagedfunction map{T <: FixedSizeVector, FName}(f::Func{FName, 2}, a::T, b::T)
	typename  = symbol("$(a.name.name)")
	arguments = [:($FName(a.($i), b.($i))) for i=1:length(T)]
    :($typename($(arguments...)))
end

const binaryOps = (:.+, :.-,:.*, :./, :.\, :.^,:*,:/,
                   :.==, :.!=, :.<, :.<=, :.>, :.>=, :+, :-,
                   :min, :max,
                   :div, :fld, :rem, :mod, :mod1, :cmp,
                   :atan2, :besselj, :bessely, :hankelh1, :hankelh2, 
                   :besseli, :besselk, :beta, :lbeta)
for op in binaryOps
    const unicsymb = gensym()

    eval(quote 
        immutable $unicsymb <: Func{symbol(string($op)), 2} end
        $op{T <: FixedSizeVector}(x::T, y::T) = map($unicsymb(), x, y)
    end)
end


gen_fixedsizevector_type(name::DataType, T::Symbol, N::Int) = gen_fixedsizevector_type(symbol(string(name.name.name)), T, N)
function gen_fixedsizevector_type(name::Symbol, T::Symbol, N::Int)
	fields = [Expr(:(::), symbol("I_$i"), T) for i = 1:N]
	typename = symbol("FS$name")
	eval(quote
		immutable $(typename){$T} <: $(name){$T}
			$(fields...)
		end
	end)
	typename
end
abstract Dimension{T} <: Number

stagedfunction getindex{FT <: FixedSizeVector, T <: Dimension}(a::FT, key::Type{T})
    index = fieldindex(a, T)
    :(T(a[$index])) 
end

macro accessors(typ, fields)
    result = Any[]
    for elem in fields.args
        push!(result, quote 
            fieldindex{T <: $typ}(::Type{T}, ::Type{$(elem.args[1])}) = $(elem.args[2])
        end)
    end
    esc(Expr(:block, result...))
end

call{T <: FixedSizeVector, ET}(t::Type{T}, data::ET...) = t(ntuple(x->data[x], length(data)))
stagedfunction call{T <: FixedSizeVector, N, ET}(t::Type{T}, data::NTuple{N, ET})
	Tsuper, Nsuper = super(T).parameters
	@assert Nsuper == N "not the right dimension"
	typename = gen_fixedsizevector_type(T, Tsuper.name, N)
	:($typename(data...))
end

immutable RGB{T} <: FixedSizeVector{T, 3}
  r::T
  g::T
  b::T
end

immutable Red{T} <: Dimension{T}
    val::T
end
immutable Green{T} <: Dimension{T}
    val::T
end
immutable Blue{T} <: Dimension{T}
    val::T
end
@accessors RGB (Red => 1, Green => 2, Blue => 3)


@show a = RGB(0.1f0,0.1f0,0.3f0)
@show a = RGB(0.1f0,0.1f0,0.3f0)
@show a = RGB(0.1f0,0.1f0,0.3f0)
@show a[Green]
@show a[2]
@show a + a
