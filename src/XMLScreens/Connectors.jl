module Connectors
using GLAbstraction
using RomeoLib

using DebugTools
export Connector, InputConnect, connect!

dodebug=RomeoLib.dodebug

type Connector
     to ::Any
     from::Any
     selectIn::Tuple{Vararg{Symbol}}
     selectOut::Tuple{Vararg{Symbol}}
end

InputConnect(from::Any,selIn::Tuple{Vararg{Symbol}},
   selOut::Tuple{Vararg{Symbol}}) =  Connector(nothing, from,  selIn, selOut)

# First get rid of special cases
function connect!(a::Connector)
     to   = a.to
     from = a.from
     if dodebug(0x04)
        println("In connect!, with Connector=$a")
        println("\t typeof(to)=\t",typeof(to))
        println("\t typeof(from)=\t",typeof(from))
     end
     if isa(to, Tuple{Vararg{Connector}})
        map(x -> connect!(a,x,from), to)
     elseif  isa(from,  Tuple{Vararg{Connector}})
        map(x -> connect!(a,to,x), from)
     else 
       connect!(a,to,from)
     end

end
connect!(ar::Array{Connector,1}) = map(connect!,ar)
connect!(a::Connector, to::RenderObject, from::Tuple{Vararg{Any}}) = map(x -> connect!(a,to,x), from)
connect!(a::Connector, to::Tuple{Vararg{Any}}, from::RenderObject) = map(x -> connect!(a,x,from), to)
# this performs the connection proper
function connect!(a::Connector, to::RenderObject, from::RenderObject)
     if  dodebug(0x04)
       println("In connect!, with Connector=$a")
       @show sort(collect(keys(from.uniforms)))
       @show sort(collect(keys(to.uniforms)))
       @show a.selectIn
       @show a.selectOut
     end
     found=false
     for i = 1 :min(length(a.selectIn),length(a.selectOut))
         if  haskey(to.uniforms,a.selectIn[i] ) && haskey(from.uniforms,a.selectOut[i]) 
            println("Connection altnum=$i from(out)=", a.selectOut[i],"\tto(in)=",a.selectIn[i])
            to.uniforms[a.selectIn[i]] = from.uniforms[a.selectOut[i]]
            found = true
         end
     end
     if !found
         warn("Unable to perform connection, pair of connectors not found")
     end
end

function connect!(a::Connector, to::Any, from::Any)
     println ("connect! ignores connection with types to=", typeof(to),"  from=", typeof(from))
     warn("Ignored potential connection because of to/from types")
end


end # module Connectors
