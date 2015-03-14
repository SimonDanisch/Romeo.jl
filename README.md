# Beginner with Romeo, an interactive scripting environment featuring OpenGL

The original page for Romeo is <A HREF="https://github.com/SimonDanisch/Romeo.jl">https://github.com/SimonDanisch/Romeo.jl</A>

# Romeo
Romeo is an interactive scripting environment, in which you can execute Julia scripts and edit the variables in 3D.

Screenshot:
![Screenshot](test/CaptureJulia.png) shows current state of my development based on Romeo.jl

### The following issues concern my own development
<TABLE>
<TR><TD>ISSUES
    <TD>Date
    <TD>Description
<TR><TD>Position window areas
    <TD>3/13/2015
    <TD>Need more precise specs on positionning of graphics and mouse focus
<TR><TD>Signals
    <TD>3/13/2015
    <TD>Are signals focused when entered via lift operation?
<TR><TD>Compiler
    <TD>3/13/2015
    <TD>ERROR: error compiling color_chooser_boundingbox: too many parameters for type Vector3
</TABLE>


### Integration of upstream changes (in  <A HREF="https://github.com/SimonDanisch/Romeo.jl">https://github.com/SimonDanisch/Romeo.jl</A>):

<TABLE>
<TR> 
     <TD>Id
     <TD>Date
     <TD>Issues
     <TD>Description
<TR> 
     <TD>ae1799a
     <TD> Fri Mar 13 21:26:21 2015
     <TD> Error in tests
     <TD>hunt_seg2.jl:
         ERROR: Ufixed8 not defined
         <BR>hunt_seg.jl:
         ERROR: syntax: extra token "map" after end of expression
         <BR> Behaviour much improved in runtest.jl (mouse and parameter entry grid functionnal)
</TABLE>

### Use of Julia 0.4 (master)
<TABLE>
<TR> 
     <TD>Id
     <TD>Date
     <TD>Issues
     <TD>Description
<TR> 
     <TD>julia 0.4.0-dev+3814<BR>GLAbstraction commit=98cafb4aae3
     <TD>Mar 14 2015
     <TD>failure to load GLAbstraction
     <TD>LoadError: UndefVarError: ColorValue not defined. <BR> This is independent of
     Romeo.
</TABLE>
