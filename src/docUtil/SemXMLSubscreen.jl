# --line 9648 --  -- from : "BigData.pamphlet"  
#== This module is used to process the output of the parse phase and
    perform all semantic actions (ie build the scene/screen).  For this,
    we navigate one big structure represented with SemNodes containing
    Dicts and Lists.

    We have not used types to garantee type security while walking this 
    structure. 
    The outer SemNode represents the <scene> and contains a list with following 
    segments
      - <subscreen>s
      - <setplot>s
      - <connection>s
      - <debug> commands
    The only tag/substructure which is recursively nested is the <subscreen>.
    We use the stateTrans from the module ParseXMLSubscreen to organise
    the walk in this <scene> list.
==#
module SemXMLSubscreen
using ParseXMLSubscreen
using SubScreens
using GLAbstraction

export  setDebugLevels,  
	buildFromParse

# --line 9676 --  -- from : "BigData.pamphlet"  
debugFlagOn  = false
debugLevel   = 0::Int64

#==       Level (ORed bit values)
              1: 
              2: 
              4: Show state transitions when state automata use fn. stateTrans
              8: 
             16: 
==#
 
#==  Set the debug parameters
==#
function setDebugLevels(flagOn::Bool,level::Int)
    global debugFlagOn
    global debugLevel
    debugFlagOn = flagOn
    debugLevel  = flagOn ? level : 0
end
# --line 9699 --  -- from : "BigData.pamphlet"  
# we use type subscreenContext to keep the context of the recursion 
# building subscreen SemNodes.

type subscreenContext
     level::Int                   # for pretty printing and such
     tree::Union(Void,String)        
     treeIndex::Array{(Int,Int),1} # see Base.getindex extension in SubScreens.jl
                                  # simpler with array, extend with vcat or push!
     builtDict::Dict{(Symbol,Symbol),Any}  
             # access built subscreens; used in finalization to fill pure references. 
             # first symbol has values 
             #    :subscreen = value is subscreen tree
             #    :name      = value is (Symbol) name of subscreen tree which may not exist yet
     finalize::Array{(Any,Int,Int,Symbol),1}       
                                  # keep list of actions needed in finalize, in the form
                                  # of (reference to array, index i, index j, identifier)
     function subscreenContext()
           nS=new()
           nS.level = 0; 
           nS.tree = nothing;  nS.treeIndex=[]; nS.builtDict=Dict{Symbol,Any}()
	   nS.finalize = Array{(Any,Int,Int,Symbol),1}(0)
           nS
     end

    #default constructor, required since no default constructor provided
     function subscreenContext(l::Int, tr::Union(Void,String),
                    ti::Array{(Int,Int),1}, bd::Dict{(Symbol,Symbol),Any},
                    f::Array{(Any,Int,Int,Symbol),1})
        nS=new()
        nS.level=l; nS.tree=tr; nS.treeIndex=ti; nS.builtDict=bd; nS.finalize = f
        nS
     end
end

# --line 9738 --  -- from : "BigData.pamphlet"  
# Let's have a pretty printer
import Base.show
function Base.show(io::IO, sc::subscreenContext)
     strs=Array{String,1}(0)
     lev = sc.level
     tree= sc.tree
     push!(strs,"subscreenContext: level=$lev,tree=$tree\n  treeIndex=[" * string(sc.treeIndex))

     push!(strs,"  builtDict=")
     for k in sort(collect(keys(sc.builtDict)))
        push!(strs, "\t" * string(k) * string(sc.builtDict[k]))
     end

     push!(strs,"  finalize=[")
     for f in sc.finalize
        push!(strs, "\t" * string(f))
     end
     push!(strs,"  ]")
     
     push!(strs,"\t]")

     print(io, reduce((x,y)->( x* "\n") * y, strs))
end

# --line 9765 --  -- from : "BigData.pamphlet"  
function buildFromParse(ast::SemNode, fnDict::Dict{String,Function})
   println("In  buildFromParse,ast=$ast")
   state::Symbol = :subscreen
   astPos::Int = 0
   const stateTransitions    = (
        (:subscreen, :setplot,    :setplot),
        (:setplot,   :connection, :connection),
        (:connection, :debug,     :debug)
   )
  # accumulate information about subscreens 
  sc = subscreenContext()

  for astItem in ast.nd
      curSym::Symbol    = astItem.nd[1]
      curAst            = astItem.nd[2]
      prevstate::Symbol = state
      state = stateTrans(state, curSym, stateTransitions)
      stateChanged = state != prevstate

      # the <subscreen> section needs finalization 
      if stateChanged && prevstate == :subscreen 
         finalizeSubscreenSection( sc)
      end

      # process <subscreen> elements
      if state == :subscreen
         processSubscreen( curAst, sc)
      elseif state == :setplot
         processSetplot( astItem, sc, fnDict)
      elseif state == :connection
         processConnection( astItem, sc)
      elseif state == :debug
         processDebug( astItem, sc)
      else
        error ("Internal error, unexpected state")
      end   # if (distinguish states)

  end # for astItem
  println("***\nAfter processing Ast")
  show(sc)
  println("***\n")
  # Now we need to return the tree remaining in SC
  # which corresponds to the key "MAIN"
  (i,s,t)=getTreeSetPtr(:MAIN,sc)
  return s
end
# --line 9824 --  -- from : "BigData.pamphlet"  
#Note no default provided for sContext since we want this to be created
#     prior to call, and to be used / analysed after this function terminates
function  processSubscreen(cur::Dict{Symbol,ParseXMLSubscreen.SemNode}, 
                           sContext::subscreenContext)

    #println("In processSubscreen at level", sContext.level)
    #println("\tcur=$cur\n***** *****")

    # distinguish cases
    s::Union(Void,SubScreen) = nothing
    if haskey(cur,:rowsizes) && haskey(cur,:colsizes)

       #create the new subscreen
       s = prepSubscreen( map(Float64,cur[:rowsizes].nd),
                          map(Float64,cur[:colsizes].nd) )
       sContext.builtDict[( :subscreen, Symbol(cur[:ident].nd))] = s
       sk = (:ident, Symbol(cur[:ident].nd))
       haskey( sContext.builtDict, sk)&& error("Logic Error: about to clobber sContext at key=$sk")
       sContext.builtDict[sk] = (sContext.tree, sContext.treeIndex)

       # walk the table describing the children
       @assert cur[:table].nd[1]  == :stable
       tbl   = cur[:table].nd[2]
       tree  = sContext.level==0 ? (cur[:ident].nd) :  sContext.tree
       for i::Int = 1:size(tbl,1), j::Int =1:size(tbl,2) 
          ntIndex = sContext.treeIndex==[] ? [(i,j),] :  
                                             vcat( sContext.treeIndex,(i,j))
          nContext =  subscreenContext( sContext.level+1, tree, ntIndex,  
                                       # these last 2 are shared (no deep copy!)
                                       sContext.builtDict, sContext.finalize
				      )
          @assert tbl[i,j].nd[1] == :subscreen
          child =  processSubscreen(tbl[i,j].nd[2], nContext) 
                     
          # now we need to insert the child in proper position, if something
          # was returned. If nothing is returned, we have a "name" placeholder
          # which was identified with an entry in builtDict, for later substitution
          # when a setplot tag is found.  
          if isa(child,SubScreen)        
             s[i,j] = child
          end
       end   # for i=..,j=...

    else  # no description, only a symbolic placeholder
       sContext.builtDict[(:ident, Symbol(cur[:ident].nd))] = (sContext.tree, sContext.treeIndex)

    end  # if (distinguish cases)

    if  haskey(cur,:attrs) &&  haskey(cur[:attrs].nd,"name")
       sContext.builtDict[(:name, Symbol(cur[:attrs].nd["name"]))] = Symbol(cur[:ident].nd)
    end

    #println("Exiting processSubscreen\n\tsubscreenContext=$sContext\n\treturning:$s")
    s
end


function    finalizeSubscreenSection(sc::subscreenContext)
    println("In finalizeSubscreenSection")

    # we want to compute  the rectangles (first, we start by doing this to
    # tree with ident= :MAIN. (then we will need to first link the trees)
    (i,s,t)  = getTreeSetPtr(:MAIN,sc)
    newTree  = computeRects(GLAbstraction.Rectangle{Float64}(0.,0.,1.,1.), s)
    # modify this in the builtDict symbol table
    scIdentSetTree!(:MAIN,newTree,sc)
end

# --line 9917 --  -- from : "BigData.pamphlet"  
# internal functions for processSetplot
function getTreeSetPtr(nm::Symbol,sc::subscreenContext)
     # builtDict is really a symbol table, where symbols belong
     # to several categories :name:       collected from xml tag, shows ident,
     #                       :ident       (tree_ident,locator index) unless
     #                      tree_ident==nothing and this represents a subscreen ,
     #                       :subscreen:  reference to subscreen tree

     # may need to do this in a try block to diagnose not found cases!!

     idt = sc.builtDict[(:name,nm)]
     tree,tloc =  sc.builtDict[(:ident,idt)]
     if tree != nothing
         idt = Symbol(tree)
     end
     subscr =  sc.builtDict[(:subscreen,idt)]
     return (idt, subscr, tloc)
end
getTreeSetPtr(nm::String,sc::subscreenContext)=getTreeSetPtr(Symbol(nm),sc)
# --line 9939 --  -- from : "BigData.pamphlet"  
    #internal function for finalizeSubscreenSection
@doc """   Associate a new tree to the name symbol nm. If keep is true,
           the old tree is kept, associated to a new id.
Start
	(:name,:MAIN)     => "sub_010"
       	(:ident,:sub_010) =>(nothing,(Int64,Int64)[])
	(:subscreen,:sub_010) => tree (SubScreen)
Result
	(:name,:MAIN)         => "sub_010"
       	(:ident,:sub_010)     =>(nothing,(Int64,Int64)[])
	(:subscreen,:sub_010) => newtree (SubScreen)
       	(:ident,:sub_new)     =>(nothing,(Int64,Int64)[])    *** keep
	(:subscreen,:sub_new) => tree (SubScreen)            *** keep
""" -> 
function scIdentSetTree!(nm::Symbol,tree::SubScreen,sc::subscreenContext,
                         keep::Bool=true)
     # make up a new identifier
     oldId = Symbol(sc.builtDict[(:name,nm)])
     if keep
         nwId  = Symbol(mkSubscreenId())
         sc.builtDict[(:ident,nwId)]      = (nothing,Array{(Int,Int),1}(0))     
         sc.builtDict[(:subscreen,nwId)]  =  sc.builtDict[(:subscreen,oldId)]
     end
     sc.builtDict[(:subscreen,oldId)] = tree     
end

# --line 9971 --  -- from : "BigData.pamphlet"  
function         processSetplot(ast::SemNode, sc::subscreenContext, 
			        fnDict::Dict{String,Function})
    #println("In  processSetplot")

    #locate the insertion pt in the subscreen tree
    (id, tree, indx) = getTreeSetPtr(ast.nd[3]["ref"],sc)
    #which function to insert?
    fn = fnDict[ast.nd[3]["fn"]]
    tree[indx...].attrib[RObjFn] = fn

    # TBD might need other actions in setplot
    println("TBD:other setplot functions")
end

function         processConnection(ast::SemNode,sc::subscreenContext)
    println("In processConnection")
    @show ast
end

function         processDebug(ast::SemNode,sc::subscreenContext)
    println("In processDebug")
    @show ast
end
# --line 9998 --  -- from : "BigData.pamphlet"  
end  # module SemXMLSubscreen
