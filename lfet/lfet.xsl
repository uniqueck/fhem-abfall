<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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
      </style>
    </HEAD>
    <BODY>
        <xsl:variable name="col-size" select="count(./Rules/Rule) + 2" />
        <table style="width:100%">
            <tr>
                <th colspan="{$col-size}"><xsl:value-of select="Title/@value"/></th>
            </tr>
            <tr>
                <th colspan="2"/>
                <xsl:for-each select="Rules/Rule">
                  <th><xsl:text>R</xsl:text><xsl:value-of select="position()" /></th>
                </xsl:for-each>
            </tr>


          <xsl:for-each select="Conditions/Condition">
            <tr>
              <td>
                <xsl:text>B</xsl:text>
                <xsl:value-of select="position()"/>
              </td>
              <td>
                <xsl:value-of select="Title/@value"/>
              </td>
              <xsl:variable name="condition-uid" select="@uId" />
              <xsl:for-each select="../../Rules/Rule">
                <td>
                  <xsl:choose>
                      <xsl:when test="ConditionLink[@link = $condition-uid and conditionState= true]">
                          <xsl:text>J</xsl:text>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="@id"/>
                      </xsl:otherwise>
                  </xsl:choose>
                </td>
              </xsl:for-each>
            </tr>
          </xsl:for-each>
        <tr></tr>
          <xsl:for-each select="Actions/Action">
            <tr>
              <td>
                <xsl:text>A</xsl:text>
                <xsl:value-of select="position()"/>
              </td>
              <td>
                <xsl:value-of select="Title/@value"/>
              </td>
            </tr>
          </xsl:for-each>

        </table>
    </BODY>
  </HTML>
</xsl:template>

</xsl:stylesheet>
