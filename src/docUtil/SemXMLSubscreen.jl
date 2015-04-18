# --line 9640 --  -- from : "BigData.pamphlet"  
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

export  setDebugLevels,  
	buildFromParse

# --line 9667 --  -- from : "BigData.pamphlet"  
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
# --line 9691 --  -- from : "BigData.pamphlet"  
# we use type subscreenContext to keep the context of the recursion 
# building subscreen SemNodes.

type subscreenContext
     level::Int                   # for pretty printing and such
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
           nS.level = 0; nS.treeIndex=[];  nS.builtDict=Dict{Symbol,Any}()
	   nS.finalize = Array{(Any,Int,Int,Symbol),1}(0)
           nS
     end

    #default constructor, required since no default constructor provided
     function subscreenContext(l::Int, ti::Array{(Int,Int),1}, bd::Dict{(Symbol,Symbol),Any},
                               f::Array{(Any,Int,Int,Symbol),1})
           nS=new()
           nS.level=l; nS.treeIndex=ti;  nS.builtDict=bd; nS.finalize = f
           nS
     end
end

# --line 9727 --  -- from : "BigData.pamphlet"  
# Let's have a pretty printer
import Base.show
function Base.show(io::IO, sc::subscreenContext)
     strs=Array{String,1}(0)
     lev = sc.level
     push!(strs,"subscreenContext: level=$lev,\n  treeIndex=[" * string(sc.treeIndex))

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

# --line 9753 --  -- from : "BigData.pamphlet"  
function buildFromParse(ast::SemNode)
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
         finalizeSubscreenSection()
      end

      # process <subscreen> elements
      if state == :subscreen
         processSubscreen(curAst, sc)
      elseif state == :setplot
         processSetplot()
      elseif state == :connection
         processConnection()
      elseif state == :debug
         processDebug()
      else
        error ("Internal error, unexpected state")
      end   # if (distinguish states)

  end # for astItem
  println("***\nAfter processing Ast")
  show(sc)
  println("***\n")

end
# --line 9809 --  -- from : "BigData.pamphlet"  
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
       sContext.builtDict[sk] = (sContext.treeIndex)

       # walk the table describing the children
       @assert cur[:table].nd[1]  == :stable
       tbl   = cur[:table].nd[2]
       for i::Int = 1:size(tbl,1), j::Int =1:size(tbl,2) 
          ntIndex = sContext.treeIndex==[] ? [(i,j),] :  
                                             vcat( sContext.treeIndex,(i,j))
          nContext =  subscreenContext( sContext.level+1, ntIndex,  
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
       sContext.builtDict[(:ident, Symbol(cur[:ident].nd))] = sContext.treeIndex

    end  # if (distinguish cases)

    if  haskey(cur,:attrs) &&  haskey(cur[:attrs].nd,"name")
       sContext.builtDict[(:name, Symbol(cur[:attrs].nd["name"]))] = Symbol(cur[:ident].nd)
    end

    #println("Exiting processSubscreen\n\tsubscreenContext=$sContext\n\treturning:$s")
    s
end


function    finalizeSubscreenSection()
    println("In finalizeSubscreenSection")
end


# --line 9873 --  -- from : "BigData.pamphlet"  
function         processSetplot()
    println("In  processSetplot")
end

function         processConnection()
    println("In processConnection")
end

function         processDebug()
    println("In processDebug")
end
# --line 9888 --  -- from : "BigData.pamphlet"  
end  # module SemXMLSubscreen
