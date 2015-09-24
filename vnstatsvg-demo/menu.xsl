<?xml version= "1.0" encoding = "UTF-8" standalone = 'no' ?>
<xsl:stylesheet version = "1.0" xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"> 
<xsl:template match="/">
  <ul class = "page"> 
    <xsl:for-each select="menu/submenu">
      <xsl:variable name="PAGE" select = "page"/> 
      <xsl:variable name="CAPTION" select = "caption"/> 
      <li class = "page" onclick="showPage('{$PAGE}','{$CAPTION}')">
	<xsl:value-of select="name"/>
      </li> 
     </xsl:for-each>
   </ul> 
</xsl:template> 
</xsl:stylesheet>
