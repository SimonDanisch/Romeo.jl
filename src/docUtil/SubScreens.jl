
# --line 8424 --  -- from : "BigData.pamphlet"  
module SubScreens

using GLAbstraction ## need Rectangle
using ROGeomOps     ## geometric OpenGL transformations on RenderObjects

export SubScreen,
        insertChildren!, prepSubscreen, computeRects, rectContextualize,
	RectangleProp,
        mkEmpty,
        treeWalk!,

        SSCAttribs, RObjFn, ROProper, sigArea, sigScreen, RORot, RODumpMe, 
        ROVirtIfDict, ROReqVirtUser, ROConnects


# --line 8443 --  -- from : "BigData.pamphlet"  
# Recursive types in Julia are found in
# http://julia.readthedocs.org/en/latest/manual/constructors/ at
# paragraph  ``Incomplete Initialization''

# this has therefore evolved into an exercise with recursive types
# NOTE: our notation for matrices and argument pertaining to matrices
#       is such that line comes before column (linenum,colnum),... etc...

# --line 8460 --  -- from : "BigData.pamphlet"  
# define subscreen as a recursive type
type SubScreen
    x::Float64
    y::Float64
    w::Float64
    h::Float64
    attrib::Dict{Symbol,Any}   # this attribute dictionnary will hold
			       # all information concerning content (e.g. 
			       # RenderObject).There will be reserved keys.
    childColW::Vector{Float64}
    childLinW::Vector{Float64}
    children::Array{Union(Nothing,SubScreen),2}

    function SubScreen(xx::Float64,yy::Float64,ww::Float64,hh::Float64)
          nS=new(); nS.x = xx ; nS.y = yy;  nS.w= ww;  nS.h = hh;
          nS.childColW=[] ;  nS.childLinW=[] ;
          nS.children = Array{Union(Nothing,SubScreen),2}(0,0)
	  nS.attrib=Dict{Symbol,Any}()
          return nS
        end


     function SubScreen(xx::Float64,yy::Float64,ww::Float64,hh::Float64,
                           linw::Vector{Float64},colw::Vector{Float64})
          nS=new(); nS.x = xx ; nS.y = yy;  nS.w= ww;  nS.h = hh
          nS.childColW = colw ; nS.childLinW = linw 
          nS.children = mkEmpty(xx,size(linw,1),size(colw,1))
	  nS.attrib=Dict{Symbol,Any}()

          # here we check that dimensions are consistent
	  @assert size(nS.children) == ( size(nS.childLinW,1), size(nS.childColW,1) )

          return nS
        end 

     function SubScreen(xx::Float64,yy::Float64,ww::Float64,hh::Float64,
                           linw::Vector{Float64},colw::Vector{Float64}, 
			   arr:: Array{Union(Nothing,SubScreen),2})
          nS=new(); nS.x = xx ; nS.y = yy;  nS.w= ww;  nS.h = hh
          nS.childColW = colw ; nS.childLinW = linw 
          nS.children = arr
	  nS.attrib=Dict{Symbol,Any}()

          # here we check that dimensions are consistent
	  @assert size(nS.children) == ( size(nS.childLinW,1), size(nS.childColW,1) )

          return nS
        end 

# NOTE: For now,the preferred way for apps/users to prepare useable 
#       SubScreens is to prepSubscreen rather than the direct interface of 
#       the constructor better suited for internal use.
# ****  !!!! ****

end  # type SubScreen

@enum SSCAttribs  SsigArea SsigScreen
# apparently,cannot use this enum to index our dicts

const sigArea     = :sigAreas
const sigScreen   = :sigScreen

const RObjFn        = :RObjFn
const ROProper      = :ROProper
const ROVirtIfDict  = :ROVirtIfDict   # Characteristics (ORed) requested by user
const ROReqVirtUser = :ROReqVirtUser # Request to perform a geometric transf
const RORot         = :RORot    #Geometric rotation (3 angles XYZ/Cardan mod2Pi)

const RODumpMe      = :RODumpMe       #Targeted debugging dump
const ROConnects= :ROConnects #follow mouse actions in a different 
				      # subscreen

# provide the required conversion so that we may index dictionnaries
import Base.convert
convert(::Type{ASCIIString},t::SSCAttribs) = string(t)
convert(::Type{Symbol},t::SSCAttribs) = :t
# --line 8544 --  -- from : "BigData.pamphlet"  
@doc """ Makes a 2D array of specified dimensions with all empty values 
         which can be put in the   field children of a SubScreen.
     """ ->
function mkEmpty(t::Float64,nl,nc)
     m = Array{Union(Void,SubScreen),2}(nl,nc)
     for i = 1:size(m,1), j = 1:size(m,2)
         m[i,j] = nothing 
     end
     m
end


# --line 8561 --  -- from : "BigData.pamphlet"  
@doc """  The SubScreen ssc receives the value newSubCell as 
          its child with coordinates (i,j) 
          sss.children[i,j] <- newSubCell
     """ ->
#
#
#
function insertChildren!( ssc::SubScreen, i::Int, j::Int,
                          newSubCell::SubScreen)
   ssc.children[i,j] = newSubCell
end
       
# --line 8576 --  -- from : "BigData.pamphlet"  
@doc """ Accesses the child described by idx of ssc. This
         walks down the SubScreen tree.
         here the syntax is:
           ssc[(i1,j1)]
           ssc[(i1,j1),(i2,j2)]

         A syntactic helper is offered (below) to handle the
         syntax:   ssc[i1,j1]
     """ ->
function Base.getindex(ssc::SubScreen, idx::(Int,Int)...)
       cur = ssc
       for i=1:length(idx)
           cur=cur.children[idx[i][1],idx[i][2]]
       end
       cur
end
# Just a syntactic helper
Base.getindex(ssc::SubScreen,i::Int,j::Int) = Base.getindex(ssc,(i,j))
# --line 8598 --  -- from : "BigData.pamphlet"  
@doc """ Sets the child described by idx of ssc to the value val. 
         This  walks down the SubScreen tree.
         here the syntax is:
           ssc[(i1,j1)]=
           ssc[(i1,j1),(i2,j2)]=

         A syntactic helper is offered (below) to handle the
         syntax:   ssc[i1,j1]=
     """ ->
function Base.setindex!(ssc::SubScreen,val::SubScreen,
                                     idx::(Int,Int)...)
       cur = ssc
       for i=1:length(idx)
           if i == length(idx)
              cur.children[ idx[i][1],idx[i][2]] = val
           else
           cur =  cur.children[idx[i][1],idx[i][2]]
           end
       end
       nothing
end

#  syntactic helper
Base.setindex!(ssc::SubScreen,val::SubScreen,i,j) =Base.setindex!(ssc,val,(i,j))

# --line 8625 --  -- from : "BigData.pamphlet"  
using Base.Enum

@enum    OptsTreeWalker preOrdr postOrdr

@doc """ Walk the SubScreen tree and apply a function at each SubScreen.
         The function receives for arguments:
            arg1 : SubScreen
            arg2 : current search index
            arg3 : Dict , initially prepared by the user, not modified by our code
            arg4 : Dict , used to convey information to the function

         treeWalk! arguments are:
            ssc  : SubScreen structure to walk recursively 
            func : Function to be applied during the wakl
            actOrdr : ordering of actions (postOrdr or preOrdr)
            indx : current search index
            misc = dict
     """ ->
function treeWalk!(ssc::SubScreen, func::Function, actOrdr:: OptsTreeWalker= preOrdr, 
                   indx::Vector{(Int64,Int64)} = Vector{(Int64,Int64)}(0) ; 
                    misc::Dict{Symbol,Any}=Dict{Symbol,Any}())
       cur = ssc
       actOrdr ==  preOrdr ?  _treeWalkPre!(ssc,func, indx; misc=misc) : 
                              _treeWalkPost!(ssc,func,indx; misc=misc)
end

@doc """ 
     """ ->
function _treeWalkPre!(ssc::SubScreen, func::Function,
                       indx::Vector{(Int64,Int64)};
		       misc::Dict{Symbol,Any}=Dict{Symbol,Any}() )
       cur = ssc

       info=Dict{Symbol,Any}(:isDecomposed=>false)
       for i = 1:size(cur.children,1),  j = 1:size(cur.children,2)
           if cur.children[i,j] !=nothing
               info[:isDecomposed]=true
               break
           end
       end
       

       # Pre: visit this node          
          # @show func
          # @show cur
          # @show indx
          # @show misc
          # @show info
          func(cur,indx,misc,info)

       # Go visit subnodes
       for i = 1:size(cur.children,1),  j = 1:size(cur.children,2)
           nindx = indx==[] ? [(i,j)] : [indx,(i,j)]

           if cur.children[i,j] !=nothing
              child=cur.children[i,j]
              _treeWalkPre!(child, func,nindx, misc=misc)
           else
              println("Leaf ($i,$j) at $indx\t$cur ")
              #here we want to look at the dimensions and the attributes
              #see what happens if we restrict this to the trees processed
              #by prepSubscreen (and specify what is expected at leaves)
           end
       end

end

@doc """  Walk the SubScreen tree and apply a function at each SubScreen.
         The function receives each SubScreen as its sole argment.
     """ ->
function _treeWalkPost!(ssc::SubScreen, func::Function, 
                       indx::Vector{(Int64,Int64)}; 
		       misc::Dict{Symbol,Any}=Dict{Symbol,Any}() )
       cur = ssc

       info=Dict{Symbol,Any}(:isDecomposed=>false)
       for i = 1:size(cur.children,1),  j = 1:size(cur.children,2)
           if cur.children[i,j] !=nothing
               info[:isDecomposed]=true
               break
           end
       end


       # Go visit subnodes
       for i = 1:size(cur.children,1),  j = 1:size(cur.children,2)
           nindx = indx==[] ? [(i,j)] : [indx,(i,j)]

           if cur.children[i,j] !=nothing
              child=cur.children[i,j]
              _treeWalkPre!(child, func, nindx, misc=misc)
           else
              println("Leaf ($i,$j) at $indx\t$cur ")
              #here we want to look at the dimensions and the attributes
              #see what happens if we restrict this to the trees processed
              #by prepSubscreen (and specify what is expected at leaves)
           end
       end

       # Post: visit this node
       func(cur,indx,misc=misc,info)       

end


# --line 8732 --  -- from : "BigData.pamphlet"  
@doc """ 
         Compute a Subscreen whose children are represented by an 
         array of SubScreen{Float}, each with position(x,y) and 
         width(w,h)(all relative to a Rectangle(0,0,1,1).          

        The arguments are two vectors indicating the relative
         sizes of the rows and of the columns.

         Connections with *actual* sizes transmitted by signals done later.

         The returned value is the  Subscreen whose children are now
         have explicit dimensions.

         While intended for internal use only, this is usefull to 
         make directly a 1 level SubScreen tree in which the children
         have been instantiated. ( No recursion for compatible sizes though!)
     """ ->
function prepSubscreen(linehRel::Vector{Float64}, colwRel::Vector{Float64})
    sumCol = sum(colwRel)
    sumLine= sum(linehRel)
    ncol =   size(colwRel)[1]
    nlig =   size(linehRel)[1]
    ret = Array(Union(SubScreen,Nothing), nlig,ncol)
    posy = zero(Float64)
    for i = 1: nlig
      posx =zero(Float64)
      h =  linehRel[i]/sumLine
      for j = 1: ncol
          w = colwRel[j] / sumCol
          ret[i,j] = SubScreen(posx::Float64,posy::Float64,w::Float64,h::Float64)
          posx = posx + w
      end
      posy = posy +h
    end

    #==  really a bypass !!!! must redo for a cleaner solution
    ==#
    sc = SubScreen (0.::Float64, 0.::Float64, 1.::Float64, 1.::Float64,
                    linehRel::Vector{Float64}, colwRel::Vector{Float64})
    for i=1:size(ret,1), j =1:size(ret,2)
       sc.children[i,j] = ret[i,j]
    end
    return sc
end
# --line 8779 --  -- from : "BigData.pamphlet"  
@doc """ Receives 2 arguments: a frame and a rect, where the 
         rect defines its relative coordinates in the frame. 
         
         Outputs the coordinates of rect in the space where frame lies.
     """ ->
function rectContextualize(frame::Rectangle{Float64}, rect::Rectangle{Float64})
     x = frame.x + frame.w * rect.x  
     y = frame.y + frame.h * rect.y  
     w =  frame.w * rect.w
     h =  frame.h * rect.h

     SubScreen(x,y,w,h)
end
# --line 8795 --  -- from : "BigData.pamphlet"  
@doc """ Extract the rectangle coordinates of a SubScreen
     """ ->
function toRectangle(ssc::SubScreen)
     Rectangle(ssc.x, ssc.y,ssc.w,ssc.h)
end
# --line 8804 --  -- from : "BigData.pamphlet"  
@doc """ Recursively builds the coordinates of the SubScreen tree,
         in the coordinate space of the root SubScreen, (where
         the root subscreen is located by its (x,y,w,h).
     """ ->
function computeRects(r::Rectangle{Float64},  ssc::SubScreen)
     if size(ssc.children) != (0,0)
        arr   = Array{Union(Nothing,SubScreen),2}(size(ssc.children)...)
        rects = prepSubscreen( ssc.  childLinW, ssc.childColW )
        for i = 1:size(ssc.children,1),  j= 1:  size(ssc.children,2)
           if ssc.children[i,j] != nothing
            v = computeRects( rectContextualize(r, toRectangle(rects[i,j])),
			      ssc.children[i,j])
            arr[i,j]  = v
           else
            # makes a leaf
            arr[i,j]  = rectContextualize(r, Rectangle(ssc.x, ssc.y, ssc.w, ssc.h))
           end
        end
        return SubScreen(float64(0.0), float64(0.0), float64(1.0), float64(1.0), 
                    ssc.childLinW, ssc.childColW, arr)
     else
        # makes a leaf, with correct sizes, since r was already applied
        return rectContextualize(r, Rectangle(0.0, 0.0 , 1.0 ,1.0))
     end
end

# --line 8834 --  -- from : "BigData.pamphlet"  
@doc """  Helper for main recursive version, repackages the first 
          arg as a SubScreen.
     """ ->
function computeRects( s::SubScreen,
                          ssc::SubScreen)
    r = Rectangle(s.x, s.y, s.w, s.h)
    computeRects(r,ssc)
end


# --line 8396 --  -- from : "BigData.pamphlet"  
@doc """
         Returns a Rectangle based on:
         Arg. 1:  a SubScreen for proportions 
         Arg. 2:  a vector representing  the (w,h) measures in the x and y 
                  directions.
     """ ->
function RectangleProp(ssc,x)
    Rectangle{Int}( int64(ssc.x*x[1]),  int64(ssc.y*x[2]),
  		    int64(ssc.w*x[1]),  int64(ssc.h*x[2]))
end

# --line 8846 --  -- from : "BigData.pamphlet"  
end # module SubScreens


