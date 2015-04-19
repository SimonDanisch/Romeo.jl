# --line 10976 --  -- from : "BigData.pamphlet"  
module TBCompletedM

export  NotComplete, TBCompleted

abstract NotComplete

@doc """
         The type TBCompleted is a wrapper for an item of type T
         which is not deemed complete (ie fit for purpose of a
         T object). 

         The function func if provided should return the
         corresponding T.

        The idea is that the user receiving a TBCompleted (or
        any other NotComplete) should make it complete before proceeding.
        This might mean calling func(what) (if func non Void) or doing
        something to be determined by the user
        
        NB :we are not in the mood of providing Ocaml style streams (although
        this might be a test!)
     """ ->
type TBCompleted{T} <: NotComplete
     what::T
     func::Union(Function,Void)
     data::Dict{Symbol,Any}
end


end # module 

