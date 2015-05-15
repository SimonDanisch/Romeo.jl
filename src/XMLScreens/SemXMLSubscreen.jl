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
        subscreenContext,  
	buildFromParse,
        xmlJuliaImport,
        insertXMLNamespace,
        showBD,
        performInits
debugFlagOn  = false
debugLevel   = UInt64(0)

#==       Level (ORed bit values)
           0x01: Show steps in syntax recognition
              2: Show final AST
              4: Show state transitions when state automata use fn. stateTrans
              8: Show steps in semantics (transition from XML to actions 
                      on subscreen tree)
           0x10: Show steps in subscreen tree indexing or manipulation
           0x20: Debug julia code inclusion and referencing
==#
 
#==  Set the debug parameters
==#
function setDebugLevels(flagOn::Bool,level::UInt64)
    global debugFlagOn
    global debugLevel
    debugFlagOn = flagOn
    debugLevel  = flagOn ? UInt64(level) : UInt64(0)
end
setDebugLevels(flagOn::Bool,level::Int) = setDebugLevels(flagOn,UInt64(level))
setDebugLevels(flagOn::Bool,level::Int32) = setDebugLevels(flagOn,UInt64(level))
setDebugLevels(flagOn::Bool,level::UInt8) = setDebugLevels(flagOn,UInt64(level))

dodebug(b::UInt8)  = debugFlagOn && ( debugLevel & UInt64(b) != 0 )
dodebug(b::UInt32) = debugFlagOn && ( debugLevel & UInt64(b) != 0 )
dodebug(b::UInt64) = debugFlagOn && ( debugLevel & UInt64(b) != 0 )
# we use type subscreenContext to keep the context of the recursion 
# building subscreen SemNodes.

type subscreenContext
     level::Int                   # for pretty printing and such
     tree::Union(Void,String)        
     treeIndex::Array{ Tuple{Int,Int},1} 
                             # see Base.getindex extension in SubScreens.jl
                             # simpler with array, extend with vcat or push!
     builtDict::Dict{Tuple{Symbol,Symbol},Any}  
             # access built subscreens; used in finalization to fill pure references. 
             # first symbol has values 
             #    :subscreen = value is subscreen tree
             #    :name      = value is (Symbol) name of rooted subscreen tree  
             #                   which  may not exist yet
             #    :locname   = value is (Symbol) name of subscreen subtree
             #    :importFn=   function entry:   second el in key pair is name of function 
             #                 which may then be used in <setplot> tags, value is callable 
             #    :module=     module entry:   second el in key pair is name of module
             #                 A priori module found here are loaded when  entry is added

     finalize::Array{Tuple{Any,Int,Int,Symbol},1}       
                                  # keep list of actions needed in finalize, in the form
                                  # of (reference to array, index i, index j, identifier)
     function subscreenContext()
           nS=new()
           nS.level = 0; 
           nS.tree = nothing;  nS.treeIndex=[]; nS.builtDict=Dict{Symbol,Any}()
	   nS.finalize = Array{ Tuple{Any,Int,Int,Symbol},1}(0)
           nS
     end

    #default constructor, required since no default constructor provided
     function subscreenContext(l::Int, tr::Union(Void,String),
               ti::Array{ Tuple{Int,Int},1}, bd::Dict{ Tuple{Symbol,Symbol},Any},
               f::Array{ Tuple{Any,Int,Int,Symbol},1})
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
function showBD(io::IO, bd::Dict{Tuple{Symbol,Symbol},Any})
     strs=Array{String,1}(0)
     for k in sort(collect(keys(bd)))
        push!(strs, "\t" * string(k) * "\t=>\t" * string(bd[k]))
     end
     print (io,  reduce((x,y)->( x* "\n") * y, strs))   
end
showBD(bd::Dict{Tuple{Symbol,Symbol},Any}) = showBD(STDOUT,bd)

function buildFromParse(ast::SemNode, sc::subscreenContext)
   dodebug(0x1) && println("In  buildFromParse,ast=$ast")
   state::Symbol = :init
   astPos::Int = 0
   const stateTransitions    = (
        (:init,      :subscreen,  :subscreen),
        (:init,      :julia,      :julia),
        (:julia,     :subscreen,  :subscreen),
        (:subscreen, :setplot,    :setplot),
        (:setplot,   :connection, :connection),
        (:setplot,   :debug,      :debug),
        (:connection, :debug,     :debug)
   )
  
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
         processSetplot( astItem, sc)
      elseif state == :connection
         processConnection( astItem, sc)
      elseif state == :debug
         processDebug( astItem, sc)
      elseif state == :julia
          # this is a special case since :julia tags may be done
          # earlier using  xmlJuliaImport (direct programmatic access
          # enabling early availability of Julia inlined code)
          if !haskey(sc.builtDict,(:xmlJuliaTags,:Done))
               processJuliaTag( astItem, sc)
          end
      else
        error ("Internal error, unexpected state")
      end   # if (distinguish states)

  end # for astItem
  if dodebug(0x2)
     println("***\nIn buildFromParse, after processing Ast")
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
         sc.builtDict[(:ident,nwId)]      = (nothing,Array{Tuple{Int,Int},1}(0))     
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

function         processSetplot(ast::SemNode, sc::subscreenContext)
    dodebug(0x08) && println("In  processSetplot\tast=$ast")

    #locate the insertion pt in the subscreen tree
    (id, tree, indx) = getTreeSetPtr(ast.nd[3]["ref"],sc)

    #which function to insert?

    # The function is now searched in the module Main.xmlNS as fn (unless there are 
    #     module issues )
    fnName = ast.nd[3]["fn"]
    impDict = sc.builtDict

    fn= searchCallable(fnName,impDict)

    # setting the function
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
        elseif item[1] == :addparm
          # Here we need to extract the relevant information from the sc
          # or organize things differently !!!!!
          tree[indx...].attrib[RObjFnParms] = item[2]
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
# Normal location for this code (but we also copy it in the scaffolding 
# for early testing of XML syntax and Julia import)
function  processJuliaTag( ast::SemNode,  sContext::subscreenContext)
    if true || dodebug(0x20) 
       println("In processJuliaTag at level ", sContext.level)
       println("\tast=$ast\n***** *****")
    end
    attrList = Array{SemNode,1}(0)
    for (elSym,elInfo) in filter((k,v)-> k== :attrs, ast.nd[2])
           push!(attrList,elInfo)
    end
    for (elSym,elInfo) in filter((k,v)-> k!= :attrs,ast.nd[2])
        elSym == :juliaCode || error("Unexpected code $elSym in processJuliaTag")
        elList = elInfo.nd
        for el in elList
            elCde = el.nd[1]
            elDtl=  el.nd[2]
            if elCde == :import
                processImport( elDtl, sContext, attrList)
            elseif  elCde == :inline
                processInline( elDtl, sContext, attrList)
            elseif  elCde == :signal
                processSignal( elDtl, sContext, attrList)
            else
               error("Unexpected detail code $elCde in processJuliaTag")
            end
        end
    end
end
# for imports we simply use the symbol table already present in sContext
function processImport( elDtl::SemNode, sContext::subscreenContext, 
                       attrL::Array{SemNode,1})
    dodebug(0x20) && println("In processImport,elDtl=$elDtl, attrL=", attrL)

    length(attrL) > 1 && error("unexpected length >1 for attrL list")
    attrs = attrL[1].nd

    impDict = sContext.builtDict
    modnm = haskey(attrs,"modulename") ? attrs["modulename"] : "Constants"

    #NOTE: for now no protection against clobbering (if multiple functions have identical name)
    eval(parse( "using "* modnm))
    modul = eval(parse( modnm))
    impDict[(:module, Symbol(modnm))] = modul

    for (k,fname) in elDtl.nd 
         k == "fn" ||  warn("Unexpected key \"$k\" in <import> tag")   
         impDict[(:importFn, Symbol(fname))] = eval(modul, parse(fname))          
    end
end

import JuliaParser.Parser
import JuliaParser.Lexer

@doc """ For signals we use the symbol table already present in sContext:
         this function inserts in sContext at key (:signalFn, NAME)
         a dictionnary with the information in the xml tag <signal>, 
         complemented with attributes from the enclosing <julia> tag. The
         "type" attribute is pre-parsed before insertion.
""" ->
function processSignal( elDtl::SemNode, sContext::subscreenContext, 
                       attrL::Array{SemNode,1})
    dodebug(0x40) && println("In processSignal,elDtl=$elDtl, attrL=", attrL)

    haskey(elDtl.nd,"name") || error("In <signal> missing attr. name")
    fnName = elDtl.nd["name"]
    sFName = Symbol(fnName)
    dict = Dict{Symbol,Any}()
    dict[:outerJulia]= attrL

    for (sk,attrVal) in elDtl.nd
         k = Symbol(sk) 
         k in (:name, :init, :advance, :type ) ||  warn(
                              "Unexpected key \"$sk\" in <signal> tag")   
         k == :name && continue
         dict[k] = (k == :type) ? Parser.parse(attrVal) : attrVal
    end
    impDict = sContext.builtDict
    impDict[(:signalFn,sFName)] = dict

    dodebug(0x40) && begin 
                 println( "In processSignal,sContext=" )
                 show( sContext )
              end
end


#here we will try to parse the provided text
function processInline( elDtl::Dict{Symbol, SemNode}, sContext::subscreenContext,
                       attrL::Array{SemNode,1})

    length(attrL) > 1 && error("unexpected length >1 for attrL list")
    attrs = attrL[1].nd
    dodebug(0x20) && println("In processInline,elDtl=$elDtl,\n\tattrs=", attrs)

    impDict = sContext.builtDict
    modnm = haskey(attrs,"modulename") ? attrs["modulename"] : ""

    body = reduce( * ,"",map (x::SemNode-> x.nd, elDtl[:juliaInline].nd))

    rx=r"^\s*(module|begin)\s+([[:alpha:]][[:alnum:]]+)"
    mtch = match(rx,body)
    if (mtch != nothing)
         dodebug(0x20) && println("Matched begin or module name:",mtch)
         if mtch.captures[1] == "begin" 
             if modnm != "*"
                #wrap in module
                body = "module defaultModule \n" * body * "\nend"
                modnm = "defaultModule"
                warn("Emitted defaultModule in processInline") 
             end
         elseif mtch.captures[1] == "module" 
             if modnm != "" && modnm != mtch.captures[2]
                warn("Module name changed to xml specification:", modnm)
                body = "module " * modnm * "\n" * body[ length(mtch.match)+1 : end]
             end
         end

    else
         body = "begin \n" * body * "\n end "
         modnm="**notInModule**"
    end

    ast = try 
        Parser.parse(body)
    catch err
        println("error in parsing:\n\t$err")
        # catch_backtrace()
        rethrow()
    end

    try 
       # we provide module Main.xmlNS as a namespace for whatever we create
       # we also keep track of the added modules, since we shall need the information
       # in processSetplot
       impDict[(:inlined,Symbol(modnm))] = eval(Main.xmlNS, ast)
       if !haskey(impDict,(:inlinedMods,:list))
          impDict[(:inlinedMods,:list)]= Array{AbstractString,1}(0)           
       end
       push!( impDict[(:inlinedMods,:list)], modnm) 
    catch err
        println("error in eval after parsing code inlined in xml file:\n\t$err")
        # catch_backtrace()
        rethrow()
    end

    
end


# we prepare a special module, in the Main module context to store
# the generated modules and other objects
function __init__()
   println ("In SemXMLSubscreen.__init__()")
   eval(Main, Parser.parse("module xmlNS  \t end"))
   global xmlNS = Main.xmlNS
end

function searchCallable(fnName::AbstractString,
                        impDict::Dict{Tuple{Symbol,Symbol},Any})
        if (haskey(impDict,(:importFn,Symbol(fnName)) ))
            dodebug(0x20) && println("In searchCallable:Looking for function ", fnName," in imports")

            f = impDict[(:importFn,Symbol(fnName))]
            dodebug(0x20) && println("\t\ttypeof(f)",typeof(f) )

            return f
        end

        if haskey(impDict,(:inlinedMods,:list))
           # use the list in impDict
           for modName in  impDict[(:inlinedMods,:list)]
              modName[1] == '*' && continue 
               dodebug(0x20) && println("In searchCallable:Looking for function ", fnName," in  Main.xmlNS.$modName")
              try 
                 fn = eval(Main.xmlNS, parse("$modName.$fnName"))
                 return fn
              catch
              end
           end
        end           

         dodebug(0x20) && println("In searchCallable:Looking for function ", fnName," in  Main.xmlNS")
         dodebug(0x20) && println("Names(Main.xmlNS):", names(Main.xmlNS))
        eval(Main.xmlNS, parse(fnName))

end

@doc """ This function performs the inits found in <julia> tags.
         In particular in <signal>, the results of the call are kept
         in the symbol table bDict, to be used later when defining
         RenderObject building functions (so that the said objects
         may contain/refer to signals).
""" ->
function  performInits(bDict::Dict{Tuple{Symbol,Symbol},Any})
   println ("Entering performInits:")
   showBD(bDict)
   println ("Exiting performInits")
end
# Provide a function to insert the functions prepared in the application
# code into the xmlNS
function  insertXMLNamespace(fdict::Dict{AbstractString, Function})
    dodebug(0x20) && println("In insertXMLNamespace, fdict=", fdict)
    for  (nm, fn) in fdict
        dodebug(0x20) &&println("\tFunction=$fn")
        expr1 = Parser.parse( nm * " = _unused_ "  )
        expr1.args[2] = fn
        eval(Main.xmlNS, expr1)
        eval(Main.xmlNS, Parser.parse("export " * nm ))
    end 

    dodebug(0x20) && println("In insertXMLNamespace, names in Main.xmlNS:", names(Main.xmlNS))
end



# This is used to permit early processing of julia tags
# enabling programmatic use of the contained definitions prior
# to semantic processing of the parseTree
function xmlJuliaImport(ast::SemNode,sc::subscreenContext)
  dodebug(0x20) && println ("Entering  xmlJuliaImport")
  for astItem in ast.nd
      curSym::Symbol    = astItem.nd[1]
      curAst            = astItem.nd[2]

      # skip tags other than :julia
      if curSym == :julia
         processJuliaTag(astItem, sc)
      end
  end  #for astItem
  sc.builtDict[(:xmlJuliaTags,:Done)] = true
 
  dodebug(0x20) && println ("At end of xmlJuliaImport")
end

end  # module SemXMLSubscreen
