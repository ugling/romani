<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

    <xsl:param name="lemma" />

    <xsl:output method="xml" indent="yes"/>

    <xsl:for-each select="//entry[o/text() = $lemma]">
        <xsl:copy-of select="." />
    </xsl:for-each>

</xsl:stylesheet>