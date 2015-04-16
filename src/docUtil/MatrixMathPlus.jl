# --line 10624 --  -- from : "BigData.pamphlet"  
module MatrixMathPlus

export norm2S,  frobNorm, 
      xtend4, xtendH, unXtend4, affineProjH    # to and from projective/homog

using ImmutableArrays

# L2 norm handled by ImmutableArrays
# L2 norm square

mydot{VT}(v1::VT,v2::VT) = sum(v1.*conj(v2))
norm2S{T}(v::Vector4{T}) = mydot(v,v)
norm2S{T}(v::Vector3{T}) = mydot(v,v)

function frobNorm{T}(m::Matrix4x4{T})
  a  =  m[1,1]*m[1,1] + m[2,1]*m[2,1] + m[3,1]*m[3,1] + m[4,1]*m[4,1]
  b  =  m[1,2]*m[1,2] + m[2,2]*m[2,2] + m[3,2]*m[3,2] + m[4,2]*m[4,2]
  c  =  m[1,3]*m[1,3] + m[2,3]*m[2,3] + m[3,3]*m[3,3] + m[4,3]*m[4,3]
  d  =  m[1,4]*m[1,4] + m[2,4]*m[2,4] + m[3,4]*m[3,4] + m[4,4]*m[4,4]
  sqrt( a + b + c + d  )
end

function xtend4{T}(v::Vector3{T}) 
    return Vector4( v[1], v[2], v[3], T(1.0))
end
xtendH{T}(v::Vector3{T}) = xtend4(v)

function unXtend4{T}(v::Vector4{T}) 
  if v[4]==T(1.0)
     return  Vector3{T}( v[1], v[2], v[3])
  else
     return  Vector3{T}( v[1], v[2], v[3])/v[4]
  end
end
affineProjH{T}(v::Vector4{T})  = unXtend4(v)

end  #  module MatrixMathPlus
