# --line 10293 --  -- from : "BigData.pamphlet"  
module Connectors

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

function connect!(a::Connector)
     to   = a.to
     from = a.from
     println("In connect!, with Connector=$a")
     println("\t typeof(to)=\t",typeof(to))
     println("\t typeof(from)=\t",typeof(from))
     println("** FOLLOWER (TO)\t[$a.selectIn]\t**")
     chkDump(to,false)
     println("** PRIMARY  (FROM)\t[$a.selectOut]\t**")
     chkDump(from,false)
     println("** PLOUF **")
     for i = 1 :min(length(a.selectIn),length(a.selectOut))
         to.uniforms[a.selectIn[i]] = from.uniforms[a.selectOut[i]]
     end
end

end # module Connectors
