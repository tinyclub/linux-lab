<?xml version= "1.0" encoding = "UTF-8" standalone = 'no' ?>
<xsl:stylesheet version = "1.0" xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"> 
<xsl:key name = "units" match = "traffic/us/u" use = "@id"/>
<xsl:template match="/">
<xsl:variable name = "TYPE" select = "traffic/@p"/>
<div>
<xsl:if test = "$TYPE != 'summary' and $TYPE != 'second'">
<div id = 'main'> 
  <xsl:variable name = "L" select = "45"/>
  <xsl:variable name = "B" select = "45"/>
  <xsl:variable name = "R" select = "20"/>
  <xsl:variable name = "T" select = "20"/>
  <xsl:variable name = "H" select = "280"/>
  <xsl:variable name = "W" select = "648"/>
  <xsl:variable name = "HR" select = "10"/>
  <xsl:variable name = "VC" select = "traffic/@colnum"/>
  <svg xmlns = "http://www.w3.org/2000/svg" xmlns:xlink = "http://www.w3.org/1999/xlink" xml:space = "preserve" width = "{$W}" height = "{$H}" viewBox = "0 0 {$W} {$H}"> 
  <g class="gra0">
    <xsl:variable name = "MAX" select = "ceiling(traffic/mf/s)"/>
    <xsl:variable name = "MAX_UNIT" select = "key('units',traffic/mf/u)/@val"/>
    <rect class="fil0 str0" x = "0" y = "0" width = "100%" height = "100%"/>
    <line class="str0" x1 = "{$L}" y1 = "{$H -$B}" x2 = "{$W -$R}" y2 = "{$H -$B}"/>
    <line class="str0" x1 = "{$L}" y1 = "{$H -$B}" x2 = "{$L}" y2 = "{$T}"/>
    <text class="anc0 fnt0" x = "{$W - $R}" y = "{$H - $T +5}">time / <xsl:value-of select = "$TYPE"/></text>    
    <text class="anc1 fnt0" x = "{$L}" y = "{$T -5}">traffic / <xsl:value-of select = "key('units',traffic/mf/u)/@sym"/></text> 
    <rect class="fil2" x = "{$L}" y = "{$H -$B +25}" width = "10" height = "10"/>
    <text class="fnt0" x = "{$L +15}" y = "{$H -$B +35}"> Receive </text> 
    <rect class="fil1" x = "{$L +100}" y = "{$H -$B +25}" width = "10" height = "10"/>
    <text class="fnt0" x = "{$L +115}" y = "{$H -$B +35}"> Transmit </text> 
    <xsl:variable name = "Xstep" select = "($W -$L -$R) div $VC"/>
    <xsl:for-each select = "traffic/r"> 
      <xsl:variable name = "X" select = "(position()-1)*$Xstep +$L"/>
      <text class="anc1 fnt1" x = "{$X +$Xstep div 2}" y = "{$H -$B +14}">
        <xsl:value-of select = "@x"/>
      </text> 
      <xsl:for-each select = "f[position() &lt; 3 ]"> 
        <xsl:variable name = "UNIT" select = "key('units',u)/@val"/>
        <xsl:variable name = "SIZE" select = "s*($UNIT div $MAX_UNIT)"/>
        <xsl:variable name = "HEIGHT" select = "$SIZE*($H -$T -$B) div $MAX"/>
        <xsl:variable name = "Y" select = "$H -$HEIGHT -$B"/>
        <xsl:variable name = "IND" select = "position() mod 2 +1"/>
        <rect class="fil{$IND}" x = "{$X +($Xstep*(position()-1) div 2)}" y = "{$Y}" width = "{$Xstep div 2}" height = "{$HEIGHT}"/>
      </xsl:for-each>
    </xsl:for-each>
    <xsl:variable name = "Ystep" select = "($H -$T -$B) div $HR"/>
    <xsl:variable name = "Yvalue" select = "$MAX div $HR"/>
    <xsl:for-each select = "//*[position() &lt; $HR ]"> 
      <xsl:if test = "position() != ($HR+1)"> 
        <line class="str1" x1 = "{$L}" y1 = "{$H -$B -position()*$Ystep}" x2 = "{$W -$R}" y2 = "{$H -$B -position()*$Ystep}"/>
        <xsl:variable name = "y" select = "substring(position()*$Yvalue, 1, 3)"/>
        <xsl:variable name = "y_last" select = "substring(position()*$Yvalue, 4, 1)"/>
	
	<xsl:if test="$y_last != '.'">
            <text class="anc1 fnt1" x = "{$L div 2}" y = "{$H -$B + 10 -position()*$Ystep}"><xsl:value-of select="concat($y, $y_last)"/></text>
	</xsl:if>
	<xsl:if test="$y_last = '.'">
            <text class="anc1 fnt1" x = "{$L div 2}" y = "{$H -$B + 10 -position()*$Ystep}"><xsl:value-of select="$y"/></text>
	</xsl:if>
      </xsl:if>
      <xsl:if test = "position() != ($VC+1)">
        <line class="str2" x1 = "{$L +position()*$Xstep}" y1 = "{$H -$B}" x2 = "{$L +position()*$Xstep}" y2 = "{$T}"/>
      </xsl:if>
    </xsl:for-each>
  </g>
  </svg>
</div> 
</xsl:if>
<div id = "main"> 
  <table width = "650" cellspacing = "0"> 
    <tbody>
      <tr> 
        <th class = "label" style = "width: 180px;"></th> 
        <th class = "label" style = "width: 174px;"> Receive </th> 
        <th class = "label" style = "width: 174px;"> Transmit </th> 
        <th class = "label" style = "width: 174px;"> Total </th> 
      </tr> 
     <xsl:for-each select = "traffic/r"> 
       <tr> 
         <xsl:variable name = "FLAG" select = "(position() mod 2)"/>
         <xsl:variable name = "START" select = "$FLAG*3+1"/>
         <xsl:variable name = "END" select = "$START+2+$FLAG"/>
         <xsl:variable name = "STYLE" select = "substring('oddeven',$START,$END)"/>
         <td class = "label_{$STYLE}">
           <xsl:value-of select = "@f1"/>
         </td> 
         <xsl:for-each select = "f"> 
           <td class = "numeric_{$STYLE}"> 
             <xsl:value-of select = "s"/>
             <xsl:value-of select = "key('units',u)/@sym"/>
           </td> 
         </xsl:for-each>
      </tr> 
     </xsl:for-each>
    </tbody> 
  </table> 
</div> 
</div>
</xsl:template> 
</xsl:stylesheet>
