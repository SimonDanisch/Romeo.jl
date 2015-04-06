
# --line 8829 --  -- from : "BigData.pamphlet"  
using SubScreens
using XtraRenderObjOGL
using DebugTools

s1=SubScreen(0.,0.,1.,1.)
s2=SubScreen(0.,0.,1.,1.)

s3=SubScreen(0.,0.,1.,1.,
                                 [4.;1.]::Vector,
				 [1.,1.]::Vector)

@assert size(s1.children)== (0,0) 
@assert size(s2.children)== (0,0)
@assert size(s3.children)== (2,2)

#
# NOTE:(TBD)For now,the preferred way for apps/users to prepare useable 
#     SubScreens is to prepSubscreen rather than the direct interface of 
#     the constructor better suited for internal use.
#

ps1= try
   # Document a spec of prepSubScreen!!!!!!!!!!!
   ps1=prepSubscreen([1.; 2.],[1.; 2.])
   ps2=prepSubscreen([1.; 2.; 3.; 4.],[1.])
   insertChildren!(ps1, 2, 2, ps2)
   ps1
catch 
   println("Error:") 
   catch_backtrace()
   rethrow()
end

println("Now testing computeRects")
#      computeRects does not modify in place, it emits a new SubScreen
ps1a = computeRects(GLAbstraction.Rectangle{Float64}(0.,0.,1000.,1000.), ps1)
s3a  = computeRects(GLAbstraction.Rectangle{Float64}(0.,0.,1000.,1000.), s3)

# Test with 3 levels  of nesting
qs1=prepSubscreen([1.; 2.],[1.; 2.])
qs2=prepSubscreen([1.; 2.; 3.; 4.],[1.])
qs3=prepSubscreen([1.; 1.],[1.; 1.])
insertChildren!(qs1, 2, 2, qs2)
insertChildren!(qs2, 2, 1, qs3)


println("Now testing indexed access")
#  Improve syntax
#s3[1,1]
s3[(1,2)]
s3[]

qs1[(2,2),(2,1)]
qs1[(2,2),(2,1),(1,1)]

println("Now testing computeRects (recursive sizing)")

#      computeRects does not modify in place, it emits a new SubScreen
s3a  = computeRects(GLAbstraction.Rectangle(0.,0.,1.,1.), s3)
ps1a = computeRects(GLAbstraction.Rectangle(0.,0.,1.,1.), ps1)
qs1a = computeRects(GLAbstraction.Rectangle(0.,0.,1.,1.), qs1)

println("Now testing tree walker")
function testFunc(ssc,indx,misc)
     println("In testFunc at $indx\tssc=$ssc")
end

# here we have an issue with the returned values of prepSubscreen

println("\n+++  +++ +++\n")
 treeWalk!(s3a, testFunc)
println("\n+++  +++ +++\n")
 treeWalk!(ps1a,testFunc)
println("\n+++  +++ +++\n")
 treeWalk!(qs1a,testFunc)

