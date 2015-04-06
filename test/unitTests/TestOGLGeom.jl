
# --line 9737 --  -- from : "BigData.pamphlet"  
using VirtualOGLGeom
using ImmutableArrays
using MatrixMathPlus

#  Test that rotation matrices are correct, in particular
#  verify that we respect the notations of Euler angles
const pi=3.1416
rm1 = rotationMatrixXYZ(pi/8.0,0.0,0.0)
rm2 = rotationMatrixEuler(pi/8.0,pi/5.0,0.0)
rm3 = rotationMatrixCardan(pi/8,pi/5.0,pi/3.0)

angles=(0.0,1.0,0.)
rm4 = rotationMatrix(angles...)

basisM =  ImmutableArrays.Matrix4x4(eye(Float64, 4))

bm1= rm1 *basisM
bm2= rm2 *basisM
bm3= rm3 *basisM
bm4= rm4 *basisM


# check orthogonality
function isOrtho{T}(m::Matrix4x4{T})
     res= m*m' - ImmutableArrays.Matrix4x4(eye(T, 4))
     frobNorm(res) < eps(1.0)*10.0
end


@assert isOrtho(bm1)
@assert isOrtho(bm2)
@assert isOrtho(bm3)
@assert isOrtho(bm4)


