# --line 10461 --  -- from : "BigData.pamphlet"  
module VirtualOGLGeom

export  rotationMatrix,
	rotationMatrixEuler,  rotationMatrixXYZ, rotationMatrixCardan,
	modelGeomApply,
	modelGeomRotate, modelGeomtranslate,
        rotateInner, translateInner,   modelSpaceXform,
	effVModelGeomCamera

# we want to use GLAbstraction's GLMatrixMath
using GLAbstraction
using ImmutableArrays
using SubScreens
using ROGeomOps
using MatrixMathPlus
# --line 10491 --  -- from : "BigData.pamphlet"  
function rotationMatrix{T}(angle::T, axis::Vector3{T})
         GLAbstraction.rotate(angle,axis)
end

# --line 10500 --  -- from : "BigData.pamphlet"  
## NOTE: more representations of rotation matrices appear in 
##       GLAbstraction.GLMatrixMath

# This one is missing in GLAbstraction.GLMatrixMath
function rotationmatrix_y{T}(angle::T)
    Matrix4x4{T}(
        Vector4{T}(cos(angle), 0  ,sin(angle), 0),
        Vector4{T}(0,          1,  0,          0),
        Vector4{T}(-sin(angle), 0  ,cos(angle), 0),
        Vector4{T}(0, 0, 0, 1))
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



# --line 10537 --  -- from : "BigData.pamphlet"  
function translationMatrix{T}(translation::Vector3{T})
       GLAbstraction.translationmatrix(translation)
end

# --line 10544 --  -- from : "BigData.pamphlet"  
function   modelGeomApply{T}(ro::RenderObject, matrix::Matrix4x4{T})
    # basic philosophy: look into ro's Virtual Function Table, grab the
    # transformation and apply it or throw error (geom transf non supported)
    vfns = ro.manipVirtuals
    haskey(vfns,VFXTransformModel) || error( 
      "The target RenderObject has no capability for model geometry modification" )
    xformFn = vfns[VFXCapabilities]
    xformFn(ro,matrix)
end
# --line 10557 --  -- from : "BigData.pamphlet"  
modelGeomRotate{T}( ro::RenderObject,angle::T, axis::Vector3{T} )=
          modelGeomApply(ro,rotationMatrix(angle, axis))
modelGeomtranslate{T}(ro::RenderObject, translation::Vector3{T} )=
          modelGeomApply(ro,translationMatrix(translation))
# --line 10568 --  -- from : "BigData.pamphlet"  
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
# --line 10601 --  -- from : "BigData.pamphlet"  
@doc """ This is performs modelSpace transformations
         ro :is a RenderObject which supports model space transformations
         matrix: is the transformation matrix in homogeneous coordinates 
""" ->
function modelSpaceXform{T}(ro::RenderObject,mat::Matrix4x4{T})
         haskey(ro.manipVirtuals,  VFXTransformModel)
         warn("TO BE IMPLEMENTED!!! ( modelSpaceXform)")
end

rotateInner{T}(ro::RenderObject,rmat::Matrix4x4{T}) = modelSpaceXform(ro,rmat)
translateInner{T}(ro::RenderObject,rmat::Matrix4x4{T}) = modelSpaceXform(ro,rmat)


# --line 10618 --  -- from : "BigData.pamphlet"  
end # module VirtualOGLGeom
