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
using ROGeomOps
using Connectors
export  setDebugLevels,  
	buildFromParse

debugFlagOn  = false
debugLevel   = 0::Int64

#==       Level (ORed bit values)
           0x01: Show steps in syntax recognition
              2: Show final AST
              4: Show state transitions when state automata use fn. stateTrans
              8: Show steps in semantics (transition from XML to actions 
                      on subscreen tree)
           0x10: Show steps in subscreen tree indexing or manipulation
==#
 
#==  Set the debug parameters
==#
function setDebugLevels(flagOn::Bool,level::Int)
    global debugFlagOn
    global debugLevel
    debugFlagOn = flagOn
    debugLevel  = flagOn ? level : 0
end

dodebug(b::UInt8)  = debugFlagOn && ( debugLevel & Int64(b) != 0 )
dodebug(b::UInt32) = debugFlagOn && ( debugLevel & Int64(b) != 0 )
dodebug(b::UInt64) = debugFlagOn && ( debugLevel & Int64(b) != 0 )

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
             #    :name      = value is (Symbol) name of rooted subscreen tree  
             #                   which  may not exist yet
             #    :locname   = value is (Symbol) name of subscreen subtree

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

# Let's have a pretty printer
import Base.show
function Base.show(io::IO, sc::subscreenContext)
     strs=Array{String,1}(0)
     lev = sc.level
     tree= sc.tree
     push!(strs,"subscreenContext: level=$lev,tree=$tree\n  treeIndex=[" * string(sc.treeIndex))

     push!(strs,"  builtDict=")
     for k in sort(collect(keys(sc.builtDict)))
        push!(strs, "\t" * string(k) * "\t=>\t" * string(sc.builtDict[k]))
     end

     push!(strs,"  finalize=[")
     for f in sc.finalize
        push!(strs, "\t" * string(f))
     end
     push!(strs,"  ]")
     
     push!(strs,"\t]")

     print(io, reduce((x,y)->( x* "\n") * y, strs))
end

function buildFromParse(ast::SemNode, fnDict::Dict{String,Function})
   dodebug(0x1) && println("In  buildFromParse,ast=$ast")
   state::Symbol = :subscreen
   astPos::Int = 0
   const stateTransitions    = (
        (:subscreen, :setplot,    :setplot),
        (:setplot,   :connection, :connection),
        (:setplot,   :debug,      :debug),
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
  if dodebug(0x2)
     println("***\nAfter processing Ast")
     show(sc)
     println("***\n")
  end
  # Now we need to return the tree remaining in SC
  # which corresponds to the key "MAIN"
  (i,s,t)=getTreeSetPtr(:MAIN,sc,:name)
  return s
end
#Note no default provided for sContext since we want this to be created
#     prior to call, and to be used / analysed after this function terminates
function  processSubscreen(cur::Dict{Symbol,ParseXMLSubscreen.SemNode}, 
                           sContext::subscreenContext)
    if (dodebug(0x8))
       println("In processSubscreen at level", sContext.level)
       println("\tcur=$cur\n***** *****")
    end

    # distinguish cases
    s::Union(Void,SubScreen) = nothing
    if haskey(cur,:rowsizes) && haskey(cur,:colsizes)

       #create the new subscreen
       s = prepSubscreen( map(Float64,cur[:rowsizes].nd),
                          map(Float64,cur[:colsizes].nd) )
       sContext.builtDict[( :subscreen, Symbol(cur[:ident].nd))] = s
       sk = (:ident, Symbol(cur[:ident].nd))
       haskey( sContext.builtDict, sk)&& error("Internal Error: about to clobber sContext at key=$sk")
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
       # distinguish names (of subscreens roots) from locnames of inner nodes
       kSym= sContext.level == 0 ? :name : :locname
       sk  = (kSym, Symbol(cur[:attrs].nd["name"]))
       haskey( sContext.builtDict, sk)&& error("Internal Error: about to clobber sContext at key=$sk")
       sContext.builtDict[sk] = Symbol(cur[:ident].nd)
    end

    dodebug(0x8) && println("Exiting processSubscreen\n\tsubscreenContext=$sContext\n\treturning:$s")
    s
end


function    finalizeSubscreenSection(sc::subscreenContext)
    dodebug(0x8) && println("In finalizeSubscreenSection")

    # we want to compute  the rectangles, but before we do that we need to
    # replace named subtrees by their value
    graftSubTrees(sc)

    # normally only the tree with name remains
    (i,s,t)  = getTreeSetPtr(:MAIN,sc,:name)
    newTree  = computeRects(GLAbstraction.Rectangle{Float64}(0.,0.,1.,1.), s)
    # modify this in the builtDict symbol table
    scIdentSetTree!( :MAIN, newTree, sc, false, :name)
end

# internal functions for processSetplot
@doc """   Lookup the sc.builtDict symbol table. find the ident for
           entry with given :name or :locname. Return: the ident, the subscreen
           tree and the locator index within the subscreen (so that one
           may access the subtree with syntax subscreen[tloc].

           The catSym arg says whether we target a :name or :locname entry
""" ->
function getTreeSetPtr(nm::Symbol,sc::subscreenContext,catSym::Symbol=:locname)
     # builtDict is really a symbol table, where symbols belong
     # to several categories :name:       collected from xml tag, shows ident,
     #                       :locname:    collected from xml tag, shows ident,
     #                       :ident       (tree_ident,locator index) unless
     #                      tree_ident==nothing and this represents a subscreen ,
     #                       :subscreen:  reference to subscreen tree

     # may need to do this in a try block to diagnose not found cases!!
     if dodebug(0x10)
         println("In getTreeSetPtr nm=$nm")
         @show sc
     end
     idt = sc.builtDict[( catSym, nm)]
     tree,tloc =  sc.builtDict[(:ident,idt)]
     if tree != nothing
         idt = Symbol(tree)
     end
     subscr =  sc.builtDict[(:subscreen,idt)]
     return (idt, subscr, tloc)
end
getTreeSetPtr(nm::String, sc::subscreenContext,catSym::Symbol=:locname) = 
    getTreeSetPtr(Symbol(nm),sc,catSym)

@doc """   Associate a new tree to the name symbol nm. If argument keep is true,
           the old tree is kept, associated to a new id.
           The catSym arg says whether we target a :name or :locname entry
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
                         keep::Bool=false, catSym::Symbol=:locname )
     # make up a new identifier
     oldId = Symbol(sc.builtDict[( catSym, nm)])
     if keep
         nwId  = Symbol(mkSubscreenId())
         sc.builtDict[(:ident,nwId)]      = (nothing,Array{(Int,Int),1}(0))     
         sc.builtDict[(:subscreen,nwId)]  =  sc.builtDict[(:subscreen,oldId)]
     end
     sc.builtDict[(:subscreen,oldId)] = tree     
end
function graftSubTrees( sc::subscreenContext )
     dodebug(0x10) && println("In graftSubTrees")
     # look for identifiers both in a :name entry and in a :locname entry
     fullTrees = map( x->x[2] , filter( x-> x[1]==:name, keys(sc.builtDict)))
     # look for references (:locnames) to full trees
     ftRefs    = filter ( x-> haskey( sc.builtDict, ( :locname, x) ), fullTrees)
      
     for nm in ftRefs
         (iM,sM,tM)         =  getTreeSetPtr(nm, sc, :name)
         (iLoc, sLoc, tLoc) =  getTreeSetPtr(nm, sc, :locname)
         dodebug(0x10) && println("***\nMAINTREE locator=", (iM,sM,tM), "\tLOC locator=", 
			          (iLoc, sLoc, tLoc),"\n***")
         # this performs the graft proper
         sLoc[tLoc...]=sM
     end
end
function         processSetplot(ast::SemNode, sc::subscreenContext, 
			        fnDict::Dict{String,Function})
    dodebug(0x08) && println("In  processSetplot\tast=$ast")

    #locate the insertion pt in the subscreen tree
    (id, tree, indx) = getTreeSetPtr(ast.nd[3]["ref"],sc)
    #which function to insert?
    fn = fnDict[ast.nd[3]["fn"]]
    tree[indx...].attrib[RObjFn] = fn

    lstCh = ast.nd[2]
    for itm in lstCh
        item=itm.nd
        if item[1] == :text
           txt=item[2]
           ismatch( r"^[\s\n]*$", "$txt") || error("Unexpected \"$txt\" text in setplot")
        elseif item[1] == :rotateModel
          tree[indx...].attrib[ROReqVirtUser] = VFRotateModel| VFTranslateModel
          tree[indx...].attrib[RORot] = item[2].nd
        else
           error("Unexpected operation in setplot:" , item[1])
        end
    end
end

function         processConnection(ast::SemNode,sc::subscreenContext)
    dodebug(0x08) && println("In processConnection")
    @show ast

   (fromId, fromTree, fromIndx) = getTreeSetPtr(ast.nd[2]["from"],sc)
   (toId,   toTree,   toIndx)   = getTreeSetPtr(ast.nd[2]["to"],sc)
   inS  = tuple(ast.nd[2][:inSig].nd[2]...)
   outS = tuple(ast.nd[2][:outSig].nd[2]...)

   #here  multiple connection may have the same target!!! Therefore make a list
   if ! haskey( toTree[toIndx...].attrib,ROConnects )
         toTree[toIndx...].attrib[ROConnects] = Array{Connector,1}(0)
   end
   push!(toTree[toIndx...].attrib[ROConnects],  InputConnect( fromTree[fromIndx...], inS, outS))
end

function         processDebug(ast::SemNode,sc::subscreenContext)
    dodebug(0x08) && println("In processDebug")
    for elDbg in ast.nd[2]
        elSym = elDbg.nd[1]
        elInfo = elDbg.nd[2]
        if  elDbg.nd[1] == :text
           ismatch( r"^[\s\n]*$", "$elInfo") || error("Unexpected \"$elInfo\" text in <debug>")
        elseif  elDbg.nd[1] == :dump
           (id, tree, indx) = getTreeSetPtr(elInfo["ref"],sc)
            tree[indx...].attrib[RODumpMe]=true
        else
           error("Unexpected tag in <debug>")
        end
    end
end
end  # module SemXMLSubscreen
