# --line 9856 --  -- from : "BigData.pamphlet"  
# here we have our debug subsection
module DebugTools

export chkDump

using GLAbstraction
using Romeo

function unitCube{T<:Number}(zero::T)
    unitcube = Array(T,4,8)
    for i=0:1, j=0:1, k=0:1 
         col = k + 2*j + 4 * i
         unitcube[1,col+1] = i
         unitcube[2,col+1] = j
         unitcube[3,col+1] = k
         unitcube[4,col+1] = 1
    end
    unitcube
end

# --line 9879 --  -- from : "BigData.pamphlet"  
#code_native( unitCube, (Int32,))
function chkDump(tup::(RenderObject...),more::Bool=false)
     for t in tup
         chkDump(t,more)
     end
end

# --line 9889 --  -- from : "BigData.pamphlet"  
function chkDump(r::RenderObject,more::Bool=false)
    println("In  chkDump(r::RenderObject)\n\t$r\n")

    cvFl =  x ->convert(Array{Float32,2},x)

    if haskey(r.uniforms, :projectionview)
         projUnitCube = cvFl(r.uniforms[:projectionview].value) * unitCube(1f0)
         println("Has projectionview")
         println("Projected (projectionview) unit cube=\n\t$projUnitCube")

    elseif haskey(r.uniforms, :projection)
         projUnitCube = cvFl(r.uniforms[:projection].value) * unitCube(1f0)
         println("Has projection")
         println("Projected (projection) unit cube=\n\t$projUnitCube")

    else
         println("No projection or projectionview in uniforms")
    end
    if more
      println("\t extended chkDump")
      for kv in  r.uniforms
          k = kv[1]
          v = kv[2]
          println("uniforms[$k]=\t$v")
      end
      println("\t Vertex Array", r.vertexarray)
    end

    println("+++  End chkDump output  +++\n")
end
# --line 9922 --  -- from : "BigData.pamphlet"  
function chkDump(d::Dict{Symbol,Any},more::Bool=false)
    println("In  chkDump(d::Dict{Symbol,Any})\n")
    for (k,v) in d
       if(isa(v,RenderObject))
         print("Dict Key $k\t")
         chkDump(v,more)
       else
         println("Dict Key $k\t==> $v")         
       end
    end
    
end

end # module DebugTools

