immutable LOL
    x::Float32
    y::Float32
    z::Float32
end

Base.start(x::LOL) = 1
Base.next(x::LOL, state::Integer) = (getfield(x, state), state+1)
Base.done(x::LOL, state) = state > length(names(LOL))

println(LOL(1,2,3)...)