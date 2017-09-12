<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exsl="http://exslt.org/common" extension-element-prefixes="exsl">

<xsl:template match="/LFET">
  <HTML>
    <HEAD>
      <style>
        div.table {
          display: table;
          border-collapse:collapse;
          width:100%;
        }
        div.tr {
          display:table-row;
        }
        div.td {
          display:table-cell;
          border:thin solid red;
          padding:5px;
        }
        div.conditionheader {
          display:table-cell;
          border:thin solid red;
          padding:5px;
          width:20px;
        }
        table, th, td {
            border: 1px solid black;
        }

      </style>
    </HEAD>
    <BODY>
        <xsl:variable name="col-size" select="count(./Rules/Rule) + 2" />
        <table style="width:100%">
            <tr>
                <th style="background-image: linear-gradient(to right, blue, lightblue);" colspan="{$col-size}"><xsl:value-of select="Title/@value"/></th>
            </tr>
            <tr>
                <th colspan="2"/>
                <xsl:for-each select="Rules/Rule">
                  <th><xsl:text>R</xsl:text><xsl:value-of select="format-number(position(),'00')" /></th>
                </xsl:for-each>
            </tr>


          <xsl:for-each select="Conditions/Condition">
            <tr>
              <td style="text-align:center">
                <xsl:text>B</xsl:text>
                <xsl:value-of select="format-number(position(),'00')"/>
              </td>
              <td>
                <xsl:value-of select="Title/@value"/>
              </td>
              <xsl:variable name="condition-uid" select="@uId" />
              <xsl:variable name="condition-occs" select="ConditionOccurrences/ConditionOccurrence" />
              <xsl:for-each select="../../Rules/Rule">
                <td style="text-align:center">
                  <xsl:choose>
                      <xsl:when test="ConditionLink[@link = $condition-uid and @conditionState = 'true']">
                          <xsl:text>J</xsl:text>
                      </xsl:when>
                      <xsl:when test="ConditionLink[@link = $condition-uid and @conditionState = 'false']">
                          <xsl:text>N</xsl:text>
                      </xsl:when>
                      <xsl:when test="exsl:node-set($condition-occs)/@uId = ConditionOccurrenceLink/@link">
                          <xsl:variable name="condition-link" select="ConditionOccurrenceLink/@link" />
                          <xsl:value-of select="//Condition[@uId = $condition-uid]/ConditionOccurrences/ConditionOccurrence[@uId = $condition-link]/Symbol/@value" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:text>-</xsl:text>
                      </xsl:otherwise>
                  </xsl:choose>
                </td>
              </xsl:for-each>
            </tr>
          </xsl:for-each>
        <tr></tr>
          <xsl:for-each select="Actions/Action">
            <tr>
              <td style="text-align:center">
                <xsl:text>A</xsl:text>
                <xsl:value-of select="format-number(position(),'00')"/>
              </td>
              <td>
                <xsl:choose>
                  <xsl:when test="count(UrlsOut/Url) = 1">
                    <xsl:variable name="urlLink" select="substring(UrlsOut/Url/@url,9)" />
                    <xsl:variable name="urlText" select="UrlsOut/Url/@title" />
                    <a href="{$urlLink}" title="{$urlText}"><xsl:value-of select="Title/@value"/></a>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="Title/@value"/>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
              <xsl:variable name="action-uid" select="@uId" />
              <xsl:variable name="action-occs" select="ActionOccurrences/ActionOccurrence" />

              <xsl:for-each select="../../Rules/Rule">
                <td style="text-align:center">
                  <xsl:choose>
                      <xsl:when test="ActionLink[@link = $action-uid]">
                          <xsl:text>X</xsl:text>
                      </xsl:when>
                      <xsl:when test="exsl:node-set($action-occs)/@uId = ActionOccurrenceLink/@link">
                          <xsl:variable name="action-link" select="ActionOccurrenceLink/@link" />
                          <xsl:value-of select="//Action[@uId = $action-uid]/ActionOccurrences/ActionOccurrence[@uId = $action-link]/Symbol/@value" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:text>-</xsl:text>
                      </xsl:otherwise>
                  </xsl:choose>
                </td>
              </xsl:for-each>
            </tr>
          </xsl:for-each>

        </table>
    </BODY>
  </HTML>
</xsl:template>

</xsl:stylesheet>
