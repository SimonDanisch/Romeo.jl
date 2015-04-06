using SubScreens
using  VirtualOGLGeom
using  ImmutableArrays


code_native(effVModelGeomCamera,(SubScreen, Vector3{Float32}, Vector3{Float32},
                                 Vector{Float32},Vector{Float32} ))



function effV1{T}(ssc::SubScreen, eyepos::Vector3{T}, 
                                                centerscene::Vector3{T},
                                                retEye::Vector{T},
                                                retcenter::Vector{T})
   if haskey(ssc.attrib,RORot) 
      angles = ssc.attrib[RORot]
      rotmat::Matrix4x4{Float32} = rotationMatrixXYZ(map(Float32,angles)...)
      cev::Vector4{T}    = xtendH(eyepos - centerscene)

      # are we rotating in the right direction?
      ncev::Vector3{T}   =Vector3{T}(0) #affineProjH(rotmat * cev)
      neye::Vector3{T}   =Vector3{T}(0) #centerscene + ncev
      for i in 1:3
          retEye[i]     = neye[i]
          retcenter[i]  = ncev[i]
      end
      return
   else
      for i in 1:3
           retEye[i]     = eyepos[i]
           retcenter[i]  = centerscene[i]
      end
      return
   end
end

function effV2{T}(ssc::SubScreen, eyepos::Vector3{T}, 
                                                centerscene::Vector3{T},
                                                retEye::Vector{T},
                                                retcenter::Vector{T})
   println("In effVModelGeomCamera\n\tssc=$ssc")
   if haskey(ssc.attrib,RORot) 
      println("effVModelGeomCamera: rotate by (angles)", (ssc.attrib[RORot]))
      angles                 = ssc.attrib[RORot]
      rotmat::Matrix4x4{T}   = rotationMatrixXYZ(map(Float32,angles)...)
      cev::Vector4{T}        = xtendH(eyepos - centerscene)

      # are we rotating in the right direction?
      ncev::Vector3{T}   = affineProjH(rotmat * cev)
      neye::Vector3{T}   = centerscene + ncev
      println ("Eye:$eyepos, Center=$centerscene, newEye=$neye")
      for i in 1:3
          retEye[i]     = neye[i]
          retcenter[i]  = ncev[i]
      end
      return
   else
      for i in 1:3
           retEye[i]     = eyepos[i]
           retcenter[i]  = centerscene[i]
      end
      return
   end
end
