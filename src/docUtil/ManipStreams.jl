# --line 3252 --  -- from : "BigData.pamphlet"  
# A set of functions to redirect streams and do similar things

module ManipStreams
using DocCompat

export redirectNewFWrite, restoreStream

@doc """ 
          This function takes a file name as argument, the corresponding
          file is created(if does not exist) , opened for write , and
          stderr is redirected to it.

          It returns a pair consisting of ( oldStream , newStream),
          which might be used to restore oldStream and close newStream.
      """ ->
function redirectNewFWrite(fname) 
      redirIOS = open(fname,"w")
      oldSTDERR= STDERR
      redirect_stderr(redirIOS)
      return ( oldSTDERR, redirIOS)
end

@doc """
         This function redirects stderr to the stream passed in argument
      """ ->
function restoreStream(oldStr)
      redirect_stderr(oldStr)
end

end # module ManipStreams
