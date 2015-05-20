module ROGeomOps

using GeometryTypes
using GLAbstraction

export 
       VFRotateModel,   VFTranslateModel,  
       VFXCapabilities, VFXTransformModel,
       hasManipVirt,    manipVirt

             # the following registry is indexed by RenderObject id (as
             # found in  field RenderObject.id)
             # The   contained Dict has some reserved fields
             #      :oid object_id as returned from Base.object_id

RORegistry = Dict{UInt16,Dict{Symbol,Any}}()

function hasManipVirt(ro::RenderObject,key::Symbol)
     println("In ROGeomOps.hasManipVirt")
     haskey(RORegistry,ro.id) && haskey(RORegistry[ro.id],key)
end

function  manipVirt(ro::RenderObject,key::Symbol)
     println("In ROGeomOps.manipVirt")
      haskey(RORegistry,ro.id) || error("RenderObject not known:" * string(ro))
      @assert ro.id ==  RORegistry[ro.id][:oid]
      return RORegistry[ro.id][key]
end

# Characteristics in RO Virtual Inteface (to appear ORed)(the user should 
# specify her requirement by seting the SubScreen attrib property ROVirtIfDict
# to the set of function she intends to use.

const VFRotateModel    = Int32(0x01)
const VFTranslateModel = Int32(0x02)

#
# Functions used to implement the Virtual Interface
# These are entry keys in the RORegistry
const VFXCapabilities  =  :VFXCapabilities
const VFXTransformModel = :VXFTransformModel

end # module ROGeomOps
