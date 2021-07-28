<?xml version='1.0' encoding='utf-8'?>
<!DOCTYPE xsl:stylesheet SYSTEM "/home/dalyw/xml/xslt/xslt.dtd">
<xsl:stylesheet version="1.1">



  <xsl:output/>

  <xsl:template match="/html">
    <html>
      <xsl:apply-templates select="head"/>
      <xsl:apply-templates select="body"/>
    </html>
  </xsl:template>

  <xsl:template match="head">
      <head>
      <xsl:apply-templates select="title"/>
      <link href="ctrgl.css" type="text/css" rel="stylesheet"/>
    </head>
  </xsl:template>

  <xsl:template match="body">
    <body>
      <header>
	<a href="index.html"><img src="Cotrugli_coin.jpg"/></a>
	<h1><xsl:value-of select="/html/head/title"/></h1>
      </header>
      <nav>
	<ul>
	  <li><a href="GL_API.html">Cotrugli Application Program Interface</a></li>
	  <li><a href="setup.html">Cotrugli Setup</a></li>
	</ul>
      </nav>

      <main>
	<xsl:apply-templates select="*"/>
      </main>

      <footer>
	<span id="copyright">
          &#169; Copyright Bill Daly, 2021. All rights reserved.
        </span>
      </footer>

    </body>

  </xsl:template>

  <xsl:template match="title">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="meta">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="a">
    <xsl:copy-of select="."/>
  </xsl:template>
  <xsl:template match="p">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="h1|h2|h3|h4|h5|h6">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="address">
    <xsl:copy-of select="."/>
  </xsl:template>

  <xsl:template match="ul"><xsl:copy-of select="."/></xsl:template>
  <xsl:template match="li"><xsl:copy-of select="."/></xsl:template>

  <xsl:template match="br"><xsl:copy-of select="."/></xsl:template>
  <xsl:template match="hr"><xsl:copy-of select="."/></xsl:template>

  <xsl:template match="pre"><xsl:copy-of select="."/></xsl:template>

  <xsl:template match="dl">
    <dl>
      <xsl:apply-templates select="dt|dd"/>
    </dl>
  </xsl:template>

  <xsl:template match="dt"><xsl:copy-of select="."/></xsl:template>
  <xsl:template match="dd"><xsl:copy-of select="."/></xsl:template>

  <xsl:template match="table">
    <table>
      <xsl:apply-templates match="thead|tbody"/>
    </table>
  </xsl:template>

  <xsl:template match="thead">
    <thead>
      <xsl:apply-templates select="tr"/>
    </thead>
  </xsl:template>

  <xsl:template match="tr">
    <tr>
      <xsl:apply-templates select="th|td"/>
    </tr>
  </xsl:template>
  
  <xsl:template match="th"><xsl:copy-of select="."/></xsl:template>
  <xsl:template match="td"><xsl:copy-of select="."/></xsl:template>

  <xsl:template match="tbody">
    <tbody>
      <xsl:apply-templates select="tr"/>
    </tbody>
  </xsl:template>

</xsl:stylesheet>
