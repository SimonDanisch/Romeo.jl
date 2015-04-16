# --line 9613 --  -- from : "BigData.pamphlet"  
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


export  setDebugLevels,  
	buildFromParse

# --line 9640 --  -- from : "BigData.pamphlet"  
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
# --line 9664 --  -- from : "BigData.pamphlet"  
# we use type subscreenContext to keep the context of the recursion 
# building subscreen SemNodes.

type subscreenContext
     level::Int                   # for pretty printing and such
     treeIndex::((Int,Int)...)    # see Base.getindex extension in SubScreens.jl
     builtDict::Dict{Symbol,Any}  # access built subscreens; used in finalization
                                  # to fill pure references. 
     finalize::Array{(Any,Int,Int,Symbol),1}       
                                  # keep list of actions needed in finalize, in the form
                                  # of (reference to array, index i, index j, identifier)
     function subscreenContext()
           nS=new()
           nS.level = 0; nS.treeIndex=();  nS.builtDict=Dict{Symbol,Any}()
	   nS.finalize = Array{(Any,Int,Int,Symbol),1}(0)
           nS
     end
end


# --line 9686 --  -- from : "BigData.pamphlet"  
function buildFromParse(ast::SemNode)
   println("In  buildFromParse,ast=$ast")
   state::Symbol = :subscreen
   astPos::Int = 0
   const stateTransitions    = (
        (:subscreen, :setplot,    :setplot),
        (:setplot,   :connection, :connection),
        (:connection, :debug,     :debug)
   ) 
  for astItem in ast.nd
      @show astItem
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
         processSubscreen(curAst)
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
end
# --line 9736 --  -- from : "BigData.pamphlet"  
function  processSubscreen(cur::Dict{Symbol,ParseXMLSubscreen.SemNode}, 
                           sContext::subscreenContext=subscreenContext())

    println("In processSubscreen at level", sContext.level)


end


function    finalizeSubscreenSection()
    println("In finalizeSubscreenSection")
end


# --line 9753 --  -- from : "BigData.pamphlet"  
function         processSetplot()
    println("In  processSetplot")
end

function         processConnection()
    println("In processConnection")
end

function         processDebug()
    println("In processDebug")
end
# --line 9768 --  -- from : "BigData.pamphlet"  
end  # module SemXMLSubscreen
