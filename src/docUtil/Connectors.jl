module Connectors
using GLAbstraction

using DebugTools
export Connector, InputConnect, connect!

type Connector
     to ::Any
     from::Any
     selectIn::(Symbol...)
     selectOut::(Symbol...)     
end

InputConnect(from::Any,selIn::(Symbol...),selOut::(Symbol...))=
     Connector(nothing, from,  selIn, selOut)

# First get rid of special cases
function connect!(a::Connector)
     to   = a.to
     from = a.from
     println("In connect!, with Connector=$a")
     println("\t typeof(to)=\t",typeof(to))
     println("\t typeof(from)=\t",typeof(from))
     if isa(to, (Connector...))
        map(x -> connect!(a,x,from), to)
     elseif  isa(from, (Connector...))
        map(x -> connect!(a,to,x), from)
     else
       connect!(a,to,from)
     end

end

connect!(a::Connector, to::RenderObject, from::(RenderObject...)) = map(x -> connect!(a,to,x), from)
connect!(a::Connector, to::(RenderObject...), from::RenderObject) = map(x -> connect!(a,x,from), to)
# this performs the connection proper
function connect!(a::Connector, to::RenderObject, from::RenderObject)
     println("In connect!, with Connector=$a")
     #@show from
     #@show to

     #println("** FOLLOWER (TO)\t[$a.selectIn]\t**")
     #chkDump(to,false)
     #println("** PRIMARY  (FROM)\t[$a.selectOut]\t**")
     #chkDump(from,false)

     @show sort(collect(keys(from.uniforms)))
     @show sort(collect(keys(to.uniforms)))
     @show a.selectIn
     @show a.selectOut
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


end # module Connectors
