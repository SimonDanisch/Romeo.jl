# Add-ons for  Romeo, an interactive scripting environment featuring OpenGL

The original page for Romeo is <A HREF="https://github.com/SimonDanisch/Romeo.jl">https://github.com/SimonDanisch/Romeo.jl</A>

# Romeo
Romeo is an interactive scripting environment, in which you can execute Julia scripts and edit the variables in 3D.

Screenshots  shows current state of my development based on Romeo.jl
<TABLE>
<TR>
    <TD><IMG SRC="test/images/ScreenShot0422.png" WIDTH=300>
    <TD><IMG SRC="test/images/ScreenShot0424.png" WIDTH=300>
</TABLE>

The first example shows: 1 main object in largest subscreen, 3 views 
of same object from directions along the 3 axes, 1 view with movements
synchronised with main object. Moreover the color output of the "colorbutton"
is transfered to several of these views. This is achieved through a **XML** 
description like the following to achieve, the result beeing shown on the last
screenshot above:
```
<?xml version="1.0" encoding="UTF-8"?>
<scene xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
             xsi:noNamespaceSchemaLocation="subscreenSchema.xsd">

<!-- Subscreen description -->

 <subscreen rows="2" cols="2" name="MAIN">
  <rowsizes>1,4</rowsizes>
  <colsizes>4,1</colsizes>
  <table>
    <tr>
     <subscreen name="A1"/>
     <subscreen name="A2"/>
     </tr>
    <tr>
     <subscreen name="B1"/>
     <subscreen name="INNER"/>
     </tr>
   </table>
 </subscreen>

 <subscreen rows="4" cols="1" name="INNER">
  <rowsizes>1,1,1,1</rowsizes>
  <colsizes>1</colsizes>
  <table>
    <tr>
     <subscreen name="IA1"/>
    </tr>
    <tr>
     <subscreen name="IB1"/>
    </tr>
    <tr>
     <subscreen name="IC1"/>
    </tr>
    <tr>
     <subscreen name="ID1"/>
    </tr>
   </table>
 </subscreen>

<!-- Subscreen contents -->

 <setplot  ref="A1"  fn="doEdit"/>
 <setplot  ref="A2"  fn="doPlot2D"/>
 <setplot  ref="B1"  fn="doPlot3D"/>

 <setplot  ref="IA1"  fn="doColorBtn"/>
 <setplot  ref="IB1"  fn="doPlot2D"> 
      <rotateModel>Pi/2, 0.0, 0.0</rotateModel>
 </setplot>
 <setplot  ref="IC1"  fn="doPlot2D">
      <rotateModel>0.0, Pi/2, 0.0</rotateModel>
 </setplot>
 <setplot  ref="ID1"  fn="doPlot2D">
      <rotateModel>0.0, 0.0, Pi/2</rotateModel>
 </setplot>

 <!-- Connectors -->
 <connection from="B1" to="A2"> 
            <inSig>:view   , :projection,    :projectionview, :projection</inSig>
            <outSig>:view , :projectionview,:projection,    :projection </outSig>
 </connection>
 <connection from="IA1" to="A2"> 
            <inSig>:color</inSig>
            <outSig>:color</outSig>
 </connection>
 <connection from="IA1" to="B1"> 
            <inSig>:color</inSig>
            <outSig>:color</outSig>
 </connection>
 <connection from="IA1" to="IC1"> 
            <inSig>:color</inSig>
            <outSig>:color</outSig>
 </connection>
 <connection from="IA1" to="ID1"> 
            <inSig>:color</inSig>
            <outSig>:color</outSig>
 </connection>


 <!-- Debug options -->

<debug>
    <dump ref="A2"/>
    <dump ref="B1"/>
    <dump ref="IA1"/>
</debug>

</scene>
<!-- This ends the scene-->

```

The following branches in the Git tree have specific meaning (At least planned):
<TABLE>
<TR><TD>master
    <TD>Eventually corresponds to master on the upstream tree 
        (S.Danisch development)
<TR><TD>Julia04
    <TD>Move to new Tuple syntax and  recent commits on Julia tree; also contains
        development done previously in branches XML, and relateSubscreens.

       Adds: Management of multiple subscreens, and inter-subscreen  interaction.
             Generalization to other signals via *Connectors* and the *connection* tag .        
</TABLE>



### The following issues concern my own development
<TABLE>
<TR><TD>ISSUES
    <TD>Date
    <TD>Description
<TR><TD>
    <TD>Sat Apr 04 2015
    <TD>Not tracking development of GLAbstraction
<TR><TD>
    <TD>Fri Apr 24 2015
    <TD>XML not validated against the xsd; xsd also needs validation
<TR><TD>Julia Version 0.4.0-dev+4500 (Commit 30b94a1*) (tried, abandonned, back to  bd748b9*)
    <TD>2015-04-25 15:54 UTC
    <TD>Issues:Reactive:does not pass its test, GLAbstraction: seem to require
        update (upstream/julia04 ?).
<TR><TD>Reactive  ad6234e1b739d34*
    <TD>Mon Apr 20 22:38:30 2015 +0530
    <TD>Issue : does not pass its test.
<TR><TD>Romeo 
    <TD>merge upstream/julia04
    <TD>merge conflicts in src/GLUniforms.jl, src/GLTypes.jl, src/GLMatrixMath.jl, src/GLCamera.jl
<TR><TD>GLAbstraction
    <TD>merged Commit 5aee885f* (Wed Apr 22 21:09:10 2015)
    <TD>Do not need anymore changes in RenderObject type definition.
<TR><TD>XML Schema based validation 
    <TD> uses xmllint
    <TD> Remaining namespace related issues in XML
</TABLE>


### Integration of upstream changes (in  <A HREF="https://github.com/SimonDanisch/Romeo.jl">https://github.com/SimonDanisch/Romeo.jl</A>):

<TABLE>
<TR> 
     <TD>Id
     <TD>Date
     <TD>Issues
     <TD>Description
<TR> 
     <TD>b1fe8580618ec94
     <TD>Sat Mar 14 12:31:48 2015
     <TD>Closed
     <TD>Example simple_display_grid.jl clarifies screen positionning, 
         signal. Shows capacity of synchronized signals in several subscreen,
         for instance ensure similar rotations upon mouse signal.
<TR> 
     <TD>1096656709a90fb
     <TD>ven. 10 avril 2015 10:37:41 CEST
     <TD>
     <TD>Solves issue with 3D plot.
</TABLE>

### Use of Julia 0.4 (master)
<TABLE>
<TR> 
     <TD>Id
     <TD>Date
     <TD>Issues
     <TD>Description
<TR> 
     <TD>Version 0.4.0-dev+4287 
     <TD> 2015-04-16 09:12 UTC
     <TD> Rebuild from source tree
     <TD> Commit bd748b9*; x86_64-linux-gnu
<TR> 
     <TD>Version 0.4.0-dev+4500
     <TD>2015-04-25 15:54 UTC
     <TD> Rebuild from source tree. Requires updates in multiple libraries (rocky): Reactive,
          GLAbstraction
     <TD> Commit  30b94a1*; x86_64-linux-gnu
</TABLE>


