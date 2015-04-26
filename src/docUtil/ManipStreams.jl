#==
 A set of function to address file/stream functionalities
    - redirect STDERR
    - full featured mkstemp (whereas Base.mktemp has more limited)
==#

module ManipStreams
#using DocCompat

export redirectNewFWrite, restoreErrStream, mkstemp

@doc """ 
          This function takes a file name as argument, the corresponding
          file is created(if does not exist) , opened for write , and
          stderr is redirected to it. Optional argument mode should be
          an open mode (default "w", "w+" for appending)

          It returns a pair consisting of ( oldStream , newStream),
          which might be used to restore oldStream and close newStream.

          Ownership of new file is transfered to the caller (this package
          does not keep information nor manages the file)
      """ ->
function redirectNewFWrite(fname,mode="w") 
      redirIOS = open(fname,mode)
      oldSTDERR= STDERR
      redirect_stderr(redirIOS)
      return ( oldSTDERR, redirIOS)
end

@doc """
         This function redirects stderr to the stream passed in argument. 
         Current file stays open and may be closed (flushed or whatever by
         owning  program (usually caller)
      """ ->
function restoreErrStream(oldStr)
      redirect_stderr(oldStr)
end
@doc """  Securely creates a new temporary file, readable and writable
          only by the current user, non executable.

          The last 6 chars of prefix must be XXXXXX.

          Returns a pair (path::String,io::IOStream)
          In case of error, will throw error after printing errno
     """ ->
function _mkstemp(; suffix=nothing, prefix=nothing,dir=nothing)
    #following code derived from Base.mktemp

    sfx= suffix==nothing ? "" : suffix
    pfx= prefix==nothing ? joinpath(tempdir(), "tmpXXXXXX") : prefix
    b  = dir != nothing && prefix!= nothing ? dir * "/" * pfx * sfx :  pfx*sfx
    p  = ccall(:mkstemps, Int32, (Ptr{UInt8}, Int32 ), b, length(sfx)) # modifies b
    if ( p == -1)
       err = errno()
       error("mkstemp failure (errno=$err)")
    end
    return (b, fdio(p, true))
end


@doc """  Securely creates a new temporary file, readable and writable
          only by the current user, non executable.

          The last 6 chars of prefix must be XXXXXX.

          Returns a pair (path::String,io::IOStream)
          In case of error, will throw error after printing errno
     """ ->
function mkstemp(prefix::ASCIIString, suffix::ASCIIString,dir::ASCIIString)
    #following code derived from Base.mktemp

    sfx= suffix
    pfx= prefix=="" ? joinpath(tempdir(), "tmpXXXXXX") : prefix
    b  = dir != "" && prefix!= "" ? sprintf("%s/%s%s",dir, pfx, sfx) :  sprintf("%s/%s", pfx,sfx)
    p  = ccall(:mkstemps, Int32, (Ptr{UInt8}, Int32 ), b, length(sfx)) # modifies b
    if ( p == -1)
       err = errno()
       error("mkstemp failure (errno=$err)")
    end
    return (b, fdio(p, true))
end

mkstemp(template::ASCIIString)=  mkstemp(template,"","")

end # module ManipStreams
