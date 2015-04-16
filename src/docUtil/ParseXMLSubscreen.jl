
# --line 9157 --  -- from : "BigData.pamphlet"  
module ParseXMLSubscreen
using LightXML

export Token, SemNode, 
       acDoc,
       stateTrans,
       setDebugLevels

# --line 9168 --  -- from : "BigData.pamphlet"  
debugFlagOn  = false
debugLevel   = 0::Int64

#==       Level (ORed bit values)
              1: 
              2: Show final AST
              4: Show state transitions when state automata use fn. stateTrans
              8: Show result of table builds
             16: Show details of table builds
==#
 
#==  Set the debug parameters
==#
function setDebugLevels(flagOn::Bool,level::Int)
    global debugFlagOn
    global debugLevel
    debugFlagOn = flagOn
    debugLevel  = flagOn ? level : 0
end



# --line 9193 --  -- from : "BigData.pamphlet"  
#==
 Token Type, which is used to choose different recursive descent options 
 via multiple dispatch
==#
 immutable Token{TokenValue}
 end
 Token(x::Symbol) = Token{x}()
 Token(x::String) = Token{Symbol(x)}()
 Token() = Token{:Default}()
# --line 9205 --  -- from : "BigData.pamphlet"  
type SemNode
    nd::Any
end
# --line 9211 --  -- from : "BigData.pamphlet"  
# utilities needed in the recursive descent parse of XML
function pretty(depth::Int,args...)
    for i=0:depth
        print("    ")
    end
    println(args...)
end

function prettyError(depth::Int,xmlel,expected)
    println("Error at depth $depth found=$xmlel\texpected=$expected")
    throw (LightXML.XMLParseError ("XML Syntax error"))
end
# --line 9226 --  -- from : "BigData.pamphlet"  
function checkSymbol(nm::Symbol,ls::(Symbol...))
   in (nm, ls) && return
   throw (LightXML.XMLParseError ("Unexpected symbol $nm not in $ls"))
end
checkSymbol(nm::String,ls::(Symbol...)) = checkSymbol(Symbol(nm),ls)

function testSymbol(nm::Symbol,ls::(Symbol...))
   return (in (nm, ls))
end
testSymbol(nm::String,ls::(Symbol...)) = testSymbol(Symbol(nm),ls)


# --line 9243 --  -- from : "BigData.pamphlet"  
function getAttr(node::XMLNode)
   if is_elementnode(node)
      el = XMLElement(node)
      ad=attributes_dict(el)
      # convert to a dict where keys are general, and where values may
      # contain any synthesized type
      ret= Dict{Any,Any}()
      merge!(ret,ad)
      ret
   end
end

# --line 9258 --  -- from : "BigData.pamphlet"  
@doc """ This is a utility function used when our semantic functions 
     are governed by a finite state automaton. Perform state transitions where
      state       : current state
      stateIndic  : indicator for possible state change
      stateTrans  : a tuple of tuples. Each inner tuple has 3 components:
                     stState, stIndic and stNew. The outer tuple is examined 
                     sequentially, when state==stState && stateIndic==stIndic
                     state is changed to stNew and the function exits. 

    The function  returns the new state if transition occurs, the old otherwise
""" ->
function stateTrans(state::Symbol, 
                     stateIndic::Symbol, 
                     stateTrans::((Symbol,Symbol,Symbol)...))
   for (stState,stIndic,stNew) in stateTrans
       if state == stState && stateIndic == stIndic
         debugFlagOn && debugLevel & 4 != 0 && println( 
                "State $state transitions to $stNew because indic=$stateIndic")
         return stNew
       end
   end
   return state
end

# --line 9285 --  -- from : "BigData.pamphlet"  
# do a recursive descent based on our Schema

# reads the xml document and build everything
function acDoc(xdoc::XMLDocument)
     res= accept(Token(:scene), root(xdoc), 0)
     debugFlagOn && debugLevel & 2 != 0 && println("Result=$res")
     res
end

acScene(xssc::XMLElement) = 
# --line 9298 --  -- from : "BigData.pamphlet"  
# We use full dispatch in order to implement a recursive descent parser
#
# This is the generic acceptor (only a development placeholder)
#
function accept{T}(tt::Token{T}, node::XMLNode, depth::Int = 0 )
     nn=name(node)
     pretty(depth, "$nn\tGA($T/$tt)")
     SemNode("GA($T/$tt)")
end
# --line 9310 --  -- from : "BigData.pamphlet"  
# This is generic function for collecting attributes; we use this trick
# to enable specific versions for checking that the proper attributes
# have been set.
#
function doAttrib{T}(tt::Token{T}, node::XMLNode, depth::Int = 0 )
   return getAttr(node)
end
# --line 9321 --  -- from : "BigData.pamphlet"  
function accept(tt::Token{:scene}, xssc::XMLElement, depth::Int=0)
    name(xssc) == "scene" || prettyError(depth,name(xssc),"scene")
    pretty(depth, "E>\t", name(xssc))
    lst = Array{SemNode,1}(0)
    # we use state to move between the  parts concerning subscreens, setplot
    # connection and  debug (see subscreenSchema.xsd )
    state::Symbol= :scene
    const stateTransitions =  (
                         (:scene,      :subscreen, :subscreen),
                         (:subscreen,  :setplot,   :setplot),
                         (:setplot, :connection,   :connection),
                         (:connection, :debug,     :debug))
    for chld in child_nodes(xssc)
        nmChild = name(chld)
        snmChild = Symbol(nmChild)

        # here we do all changes of state before the 'if'
        state = stateTrans(state, Symbol(nmChild),stateTransitions)

        # action according to state (we skip comment and text)
        if (   state == :scene 
            && testSymbol( nmChild , (:rootscreen, :comment, :text)))
           if snmChild == :scene   
             push!(lst,accept(Token(nmChild), chld, depth+1))
           end
        elseif (   state == :subscreen  
            && testSymbol( nmChild , (:subscreen, :comment, :text)))
           if snmChild == :subscreen
             push!(lst,accept(Token(nmChild), chld, depth+1))
           end
        elseif(   state == :setplot 
            && testSymbol( nmChild , (:setplot, :comment, :text)))
           if snmChild == :setplot
              push!(lst,accept(Token(nmChild), chld, depth+1))
           end
        elseif(   state == :connection 
            && testSymbol( nmChild , (:connection, :comment, :text)))
           if snmChild == :connection
              push!(lst,accept(Token(nmChild), chld, depth+1))
           end
        elseif (   state == :debug  
            && testSymbol( nmChild , (:debug, :comment, :text)))
           if snmChild == :debug
              push!(lst,accept(Token(nmChild), chld, depth+1))
           end
        else
            error("Unexpected token \"$nmChild\"  in <scene> section")
        end

    end  # for loop
    SemNode(lst)
end

# --line 9377 --  -- from : "BigData.pamphlet"  
global subsCount=0
function accept(tt::Token{:subscreen}, xnd::XMLNode, depth::Int=0)
    global subsCount
    pretty(depth, "N>\t",name(xnd), getAttr(xnd))
    bld = Dict{Symbol,SemNode}()

    attribs = doAttrib(tt,xnd,depth)
    # we use state to move between the  parts concerning subscreens, setplot
    # connection and  debug (see subscreenSchema.xsd )
    state::Symbol= :rowsizes
    const stateTransitions =  (
                         (:rowsizes, :colsizes, :colsizes),
                         (:colsizes,  :table,   :table))
    for chld in child_nodes(xnd)
        nmChild = name(chld)
        snmChild = Symbol(nmChild)

        # here we do all changes of state before the 'if'
        state = stateTrans(state, Symbol(nmChild),stateTransitions)

        # action according to state (we skip comment and text)
        if (   state == :rowsizes 
            && testSymbol( nmChild , (:rowsizes, :comment, :text)))
           if snmChild == :rowsizes   
             bld[:rowsizes] = accept(Token(:listInt), chld, depth+1)
           end
        elseif (   state == :colsizes 
            && testSymbol( nmChild , (:colsizes, :comment, :text)))
           if snmChild == :colsizes   
             bld[:colsizes] = accept(Token(:listInt), chld, depth+1)
           end
        elseif (   state == :table 
            && testSymbol( nmChild , (:table, :comment, :text)))
           if snmChild == :table
             bld[:table]= accept(Token(nmChild), chld, depth+1)
           end
        else
            error("Unexpected token \"$nmChild\"  in <subscreen> section")
        end # if state
    end  # for loop

    subsCount = subsCount+1
    bld[:ident]=SemNode("sub_$subsCount")
    subsTblSimplify!(bld)
    SemNode((:subscreen,bld))
end

# --line 9427 --  -- from : "BigData.pamphlet"  
function accept(tt::Token{:table}, xnd::XMLNode, depth::Int=0)
    pretty(depth, "N>\t",name(xnd))
    tbl = Array{SemNode,1}(0)
    for chld in child_nodes(xnd)
        nmchld  = name(chld)
        snmchld = Symbol(nmchld)
        checkSymbol ( nmchld , (:tr, :text, :comment ))
        if snmchld ==:tr
           aa = accept(Token( nmchld), chld, depth+1)
           append!(tbl, [aa])
        else   
         ismatch( r"^[\s\n]*$", "$chld") || error(
                    "in <table> Ignored child \"$chld\"")
        end
    end
    SemNode((:table,tbl))
end
# --line 9447 --  -- from : "BigData.pamphlet"  
function accept(tt::Token{:tr}, xnd::XMLNode, depth::Int=0)
    pretty(depth, "N>\t",name(xnd))
    tbl = Array{SemNode,1}(0)
    for chld in child_nodes(xnd)
        nmchld  = name(chld)
        snmchld = Symbol(nmchld)
        checkSymbol ( nmchld , (:subscreen, :text ))
        if snmchld ==:subscreen
           aa = accept(Token(nmchld), chld, depth+1)
           append!(tbl, [aa])
        else 
          ismatch( r"^[\s\n]*$", "$chld") || error(
              "in <gr-line> Ignored child \"$chld\"")
        end
    end
    SemNode((:tr,tbl))
end


# --line 9469 --  -- from : "BigData.pamphlet"  
function accept(tt::Token{:setplot}, xnd::XMLNode, depth::Int=0)
    pretty(depth, "S>\t", name(xnd), getAttr(xnd))
    attrs = getAttr(xnd)
    # here the attribute (fn) are essential!!!!
    tbl = Array{SemNode,1}(0)
    for chld in child_nodes(xnd)
        checkSymbol (name(chld) , (:rotateModel, :text ))
        push!(tbl,accept(Token(name(chld)), chld, depth+1))
    end
    SemNode((:setplot,tbl, attrs))
    
end

# --line 9485 --  -- from : "BigData.pamphlet"  
function accept(tt::Token{:connection}, xnd::XMLNode, depth::Int=0)
    pretty(depth, "C>\t",name(xnd))
    attrs = getAttr(xnd)
    for chld in child_nodes(xnd)
        checkSymbol (name(chld) , (:inSig, :outSig,:text ))
        attrs[Token(name(chld))] = accept(Token(name(chld)), chld, depth+1)
    end
    SemNode((:connection,attrs))
end

function accept(tt::Union(Token{:inSig},Token{:outSig}), 
                xnd::XMLNode, depth::Int=0)
    pretty(depth, "SIG>\t",name(xnd))
    lst=Array{Any,1}(0)
    for chld in child_nodes(xnd)
      push!(lst, string(chld))
    end    
    SemNode((name(xnd),lst))

end
# --line 9509 --  -- from : "BigData.pamphlet"  
function accept(tt::Token{:rotateModel},  xnd::XMLNode, depth::Int=0)
    pretty(depth, "RotateModel>\t",name(xnd))        
    SemNode("TBD:RotateModel")
end
# --line 9516 --  -- from : "BigData.pamphlet"  
function accept(tt::Token{:dump},  xnd::XMLNode, depth::Int=0)
    pretty(depth, "Dump>\t",name(xnd))        
    SemNode("TBD:Dump")
end
# --line 9524 --  -- from : "BigData.pamphlet"  
function accept(tt::Token{:listInt},  xnd::XMLNode, depth::Int=0)
    lst=Array{Int64,1}(0)
    for chld in      child_nodes(xnd)
        t = content(chld)  # text content 
        lst= map( s -> parseint(Int64,s), split(t,",") )
    end    
    SemNode(lst)

end
# --line 9536 --  -- from : "BigData.pamphlet"  
function accept(tt::Token{:listFloat},  xnd::XMLNode, depth::Int=0)
    lst=Array{Float64,1}(0)
    for chld in      child_nodes(xnd)
        t = content(chld)  # text content 
        lst = map( s -> parseint(Float64,s), split(t,",") )
    end    
    SemNode(lst)
end
# --line 9549 --  -- from : "BigData.pamphlet"  
function accept(tt::Token{:text}, xnd::XMLNode, depth::Int=0)
    c = content(xnd)
    ret=if  ! ismatch( r"^[\s\n]*$", c)
        pretty(depth, "N>\t", name(xnd), "\"",c,"\"")
        content(c)
    else
       ""
    end
    SemNode((:text,ret))
end

# --line 9563 --  -- from : "BigData.pamphlet"  
function accept(tt::Token{:debug}, xnd::XMLNode, depth::Int=0)
    pretty(depth, "D>\t",name(xnd))
    for chld in child_nodes(xnd)
        accept(Token(name(chld)), chld, depth+1)
    end
    SemNode("TBD:debug")
end
# --line 9573 --  -- from : "BigData.pamphlet"  
# this transform accumulated vector of vectors into 2D table
function subsTblSimplify!(bld::Dict{Symbol,SemNode})
     
    haskey(bld,:table) || return     # do not worry about subscreen placehoders

    debugFlagOn && debugLevel & 16 != 0 && println("In  subsTblSimplify!")

    rowsizes = bld[:rowsizes].nd
    colsizes = bld[:colsizes].nd
    tb       = bld[:table].nd[2]

    newTbl   = Array{SemNode,2}( length(rowsizes), length(colsizes) )
    debugFlagOn && debugLevel & 16 != 0 && println(
          "length(tb)=", length(tb), "\tlength(rowsizes)=", length(rowsizes) )
    @assert length(tb) == length(rowsizes)
    i::Int = 0
    for r in tb
        i+=1
        row = r.nd[2]
        debugFlagOn && debugLevel & 16 != 0 &&  println(
                 "length(row)",length(row),"length(colsizes)",length(colsizes))
        @assert length(row) == length(colsizes)
        j::Int = 0
        for c in row
           j += 1
           newTbl[i,j] = c
        end
    end
    bld[:table] = SemNode((:stable,newTbl))
    debugFlagOn && debugLevel & 24 != 0 &&  println(
                 "subsTblSimplify returns bld=$bld")
end

# --line 9609 --  -- from : "BigData.pamphlet"  
end # module ParseXMLSubscreen
