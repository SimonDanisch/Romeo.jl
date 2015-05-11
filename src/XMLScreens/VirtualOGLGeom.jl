module VirtualOGLGeom

export  rotationMatrix,
	rotationMatrixEuler,  rotationMatrixXYZ, rotationMatrixCardan,
	modelGeomApply,
	modelGeomRotate, modelGeomtranslate,
        rotateInner, translateInner,   modelSpaceXform,
	effVModelGeomCamera

# we want to use GLAbstraction's GLMatrixMath
using GLAbstraction
using GeometryTypes
using SubScreens
using ROGeomOps
using MatrixMathPlus
function rotationMatrix{T}(angle::T, axis::Vector3{T})
         GLAbstraction.rotate(angle,axis)
end

## NOTE: more representations of rotation matrices appear in 
##       GLAbstraction.GLMatrixMath

# This one is missing in GLAbstraction.GLMatrixMath
function rotationmatrix_y{T}(angle::T)
    Matrix4x4{T}(
        cos(angle),  0  ,sin(angle), 0 ,
        0,           1,  0,          0,
        -sin(angle), 0  ,cos(angle), 0,
        0, 0, 0, 1 )
end

# This is the Euler decomposition of a 3D rotation
# 
function rotationMatrixEuler{T}(phi::T, theta::T, psi::T)
      B = rotationmatrix_z( phi )
      C = rotationmatrix_x( theta )
      D = rotationmatrix_z( psi )
      B * C * D
end

# This is the Cardan decomposition of a 3D rotation
function rotationMatrixXYZ{T}(phi::T, theta::T, psi::T)
      B = rotationmatrix_x( phi )
      C = rotationmatrix_y( theta )
      D = rotationmatrix_z( psi )
      D * C * B
end

rotationMatrixCardan{T}(phi::T, theta::T, psi::T)=rotationMatrixXYZ(phi,
                                theta, psi)



function translationMatrix{T}(translation::Vector3{T})
       GLAbstraction.translationmatrix(translation)
end

function   modelGeomApply{T}(ro::RenderObject, matrix::Matrix4x4{T})

    hasManipVirt(ro, VFXTransformModel )|| error( 
      "The target RenderObject has no capability for model geometry modification" )
    xformFn = manipVirt( ro, VFXCapabilities)
    xformFn(ro,matrix)
end
modelGeomRotate{T}( ro::RenderObject,angle::T, axis::Vector3{T} )=
          modelGeomApply(ro,rotationMatrix(angle, axis))
modelGeomtranslate{T}(ro::RenderObject, translation::Vector3{T} )=
          modelGeomApply(ro,translationMatrix(translation))
@doc  """ This function performs the geometric transformation on
          model space when this is amenable to camera or camera
          parameter changes
          It acts on the camera parameters independently of the 
          RenderObject;it uses the user's candidates for eyepos 
          and centerScene, for which it outputs corrected values.

          Argument:
               ssc::Subscreen; the rotation specification is ssc.attrib[RORot]
               eyepos::Vector3
               centerScene::Vector3
          Returns a pair (eyepos,centerScene) that can both be fed into
          a camera as Vector3.
""" ->
function effVModelGeomCamera{T}(ssc::SubScreen, eyepos::Vector3{T}, 
                                                centerscene::Vector3{T})
   if haskey(ssc.attrib,RORot) 
      angles                 = ssc.attrib[RORot]
      rotmat::Matrix4x4{T}   = rotationMatrixXYZ(map(Float32,angles)...)
      cev::Vector4{T}        = xtendH(eyepos - centerscene)

      # are we rotating in the right direction?
      ncev::Vector3{T}   = affineProjH(rotmat * cev)
      neye::Vector3{T}   = centerscene + ncev
      return  neye, centerscene
   else
      return  eyepos, centerscene
   end
end
@doc """ This performs modelSpace transformations
         ro :is a RenderObject which supports model space transformations
         matrix: is the transformation matrix in homogeneous coordinates 
""" ->
function modelSpaceXform{T}(ro::RenderObject,mat::Matrix4x4{T})
         hasManipVirt(ro,  VFXTransformModel)
         warn("TO BE IMPLEMENTED!!! ( modelSpaceXform)")
end

rotateInner{T}(ro::RenderObject,rmat::Matrix4x4{T}) = modelSpaceXform(ro,rmat)
translateInner{T}(ro::RenderObject,rmat::Matrix4x4{T}) = modelSpaceXform(ro,rmat)


end # module VirtualOGLGeom
