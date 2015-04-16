# --line 9786 --  -- from : "BigData.pamphlet"  
module ROGeomOps

using ImmutableArrays
using GLAbstraction

export 
       VFRotateModel, VFTranslateModel,  
       VFXCapabilities, VFXTransformModel


# --line 9803 --  -- from : "BigData.pamphlet"  
# Characteristics in RO Virtual Inteface (to appear ORed)(the user should 
# specify her requirement by seting the SubScreen attrib property ROVirtIfDict
# to the set of function she intends to use.

const VFRotateModel    = Int32(0x01)
const VFTranslateModel = Int32(0x02)

#
# Functions used to implement the Virtual Interface
# These are entry keys in the manipVirtual directory
const VFXCapabilities  =  :VFXCapabilities
const VFXTransformModel = :VXFTransformModel

# --line 9819 --  -- from : "BigData.pamphlet"  
end # module ROGeomOps
