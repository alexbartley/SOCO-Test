CREATE OR REPLACE PACKAGE BODY content_repo.dev_piped_results
-- Some ideas for the PHP stuff

/* Formatted on 1/7/2014 2:09:10 PM (QP5 v5.150) */
IS
  g_json_null_object             constant varchar2(20) := '{ }';

function get_xml_to_json_stylesheet return varchar2
as
begin
  /*
  SEE http://code.google.com/p/xml2json-xslt
  */


  /*
  Purpose:    return XSLT stylesheet for XML to JSON transformation
  Who     Date        Description
  ------  ----------  -------------------------------------
  Orig. MBR     30.01.2010  Created
  Added fix for nulls

  */
  --
  return '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!--
  Copyright (c) 2006, Doeke Zanstra
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

  Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer. Redistributions in binary
  form must reproduce the above copyright notice, this list of conditions and the
  following disclaimer in the documentation and/or other materials provided with
  the distribution.

  Neither the name of the dzLib nor the names of its contributors may be used to
  endorse or promote products derived from this software without specific prior
  written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
  THE POSSIBILITY OF SUCH DAMAGE.
-->

  <xsl:output indent="no" omit-xml-declaration="yes" method="text" encoding="UTF-8" media-type="text/x-json"/>
  <xsl:strip-space elements="*"/>
  <!--contant-->
  <xsl:variable name="d">0123456789</xsl:variable>

  <!-- ignore document text -->
  <xsl:template match="text()[preceding-sibling::node() or following-sibling::node()]"/>

  <!-- string -->
  <xsl:template match="text()">
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="."/>
    </xsl:call-template>
  </xsl:template>

  <!-- Main template for escaping strings; used by above template and for object-properties
       Responsibilities: placed quotes around string, and chain up to next filter, escape-bs-string -->
  <xsl:template name="escape-string">
    <xsl:param name="s"/>
    <xsl:text>"</xsl:text>
    <xsl:call-template name="escape-bs-string">
      <xsl:with-param name="s" select="$s"/>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
  </xsl:template>

  <!-- Escape the backslash (\) before everything else. -->
  <xsl:template name="escape-bs-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,''\'')">
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''\''),''\\'')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-bs-string">
          <xsl:with-param name="s" select="substring-after($s,''\'')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Escape the double quote ("). -->
  <xsl:template name="escape-quot-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,''&quot;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&quot;''),''\&quot;'')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="substring-after($s,''&quot;'')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Replace tab, line feed and/or carriage return by its matching escape code. Can''t escape backslash
       or double quote here, because they don''t replace characters (&#x0; becomes \t), but they prefix
       characters (\ becomes \\). Besides, backslash should be seperate anyway, because it should be
       processed first. This function can''t do that. -->
  <xsl:template name="encode-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <!-- tab -->
      <xsl:when test="contains($s,''&#x9;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#x9;''),''\t'',substring-after($s,''&#x9;''))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- line feed -->
      <xsl:when test="contains($s,''&#xA;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#xA;''),''\n'',substring-after($s,''&#xA;''))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- carriage return -->
      <xsl:when test="contains($s,''&#xD;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#xD;''),''\r'',substring-after($s,''&#xD;''))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$s"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- number (no support for javascript mantise) -->
  <xsl:template match="text()[not(string(number())=''NaN'')]">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- boolean, case-insensitive -->
  <xsl:template match="text()[translate(.,''TRUE'',''true'')=''true'']">true</xsl:template>
  <xsl:template match="text()[translate(.,''FALSE'',''false'')=''false'']">false</xsl:template>

  <!-- item:null -->
  <xsl:template match="*[count(child::node())=0]">
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="local-name()"/>
    </xsl:call-template>
    <xsl:text>:null</xsl:text>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">}</xsl:if> <!-- MBR 30.01.2010: added this line as it appeared to be missing from stylesheet -->
  </xsl:template>

  <!-- object -->
  <xsl:template match="*" name="base">
    <xsl:if test="not(preceding-sibling::*)">{</xsl:if>
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="name()"/>
    </xsl:call-template>
    <xsl:text>:</xsl:text>
    <xsl:apply-templates select="child::node()"/>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">}</xsl:if>
  </xsl:template>

  <!-- array -->
  <xsl:template match="*[count(../*[name(../*)=name(.)])=count(../*) and count(../*)&gt;1]">
    <xsl:if test="not(preceding-sibling::*)">[</xsl:if>
    <xsl:choose>
      <xsl:when test="not(child::node())">
        <xsl:text>null</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="child::node()"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">]</xsl:if>
  </xsl:template>

  <!-- convert root element to an anonymous container -->
  <xsl:template match="/">
    <xsl:apply-templates select="node()"/>
  </xsl:template>

</xsl:stylesheet>';
end get_xml_to_json_stylesheet;

    -- SQL: select * from table(dev_piped_results.return_table);
    FUNCTION return_table
/*ADVICE(5): Function has no parameters [514]
so?
*/
        RETURN t_nested_table
/*ADVICE(7): This item has not been declared, or it refers to a label [131]
it's just a type
*/
        PIPELINED
    IS
        l_row   t_col;
/*ADVICE(11): This item has not been declared, or it refers to a label [131] */
    BEGIN
        l_row.i := 1;
        l_row.n := 'one';
        PIPE ROW (l_row);
        l_row.i := 2;
        l_row.n := 'two';
        PIPE ROW (l_row);
        RETURN;
    END return_table;
/*ADVICE(21): END of program unit, package or type is not labeled [408]
it is now...
*/

/*
This was the orig. format I wanted to send to PHP...
    FUNCTION return_commd (vtxt IN VARCHAR2)
        RETURN otcommodities
        PIPELINED
    IS
        CURSOR cc
        IS
            SELECT c.id, c.name, c.description
              FROM commodities c;

        TYPE tbl_join IS TABLE OF cc%ROWTYPE;

        l_table   tbl_join;
    BEGIN
        NULL;
        RETURN;
    END return_commd;
*/

    FUNCTION refcursjson (p_ref_cursor   IN SYS_REFCURSOR,
                          p_max_rows     IN NUMBER := NULL,
                          p_skip_rows    IN NUMBER := NULL)
        RETURN CLOB
    IS
        l_ctx           DBMS_XMLGEN.ctxhandle;
        --
        l_num_rows      PLS_INTEGER;
        l_xml           XMLTYPE;
        l_json          XMLTYPE;
        l_returnvalue   CLOB;
    BEGIN
        l_ctx := DBMS_XMLGEN.newcontext (p_ref_cursor);
        DBMS_XMLGEN.setnullhandling (l_ctx, DBMS_XMLGEN.empty_tag);

        -- Pagination "give me" and "skip to"
        IF p_max_rows IS NOT NULL
        THEN
            DBMS_XMLGEN.setmaxrows (l_ctx, p_max_rows);
        END IF;

        IF p_skip_rows IS NOT NULL
        THEN
            DBMS_XMLGEN.setskiprows (l_ctx, p_skip_rows);
        END IF;

-- XML content
        l_xml := DBMS_XMLGEN.getxmltype (l_ctx, DBMS_XMLGEN.none);
        l_num_rows := DBMS_XMLGEN.getnumrowsprocessed (l_ctx);
        DBMS_XMLGEN.closecontext (l_ctx);

-- tnn:  need to add a check here to see if it was a valid cursor
        CLOSE p_ref_cursor;

        IF l_num_rows > 0
        THEN
            -- XSL transformation
            l_json:=l_xml.transform (xmltype (get_xml_to_json_stylesheet));
            l_returnvalue:=l_json.getclobval ();
        ELSE
            l_returnvalue:=g_json_null_object;
        END IF;
        l_returnvalue:=DBMS_XMLGEN.CONVERT (l_returnvalue, DBMS_XMLGEN.entity_decode);
        RETURN l_returnvalue;
    END refcursjson;


    PROCEDURE change_log_search(
              entity IN VARCHAR2,
              search_ModifBy IN VARCHAR2,
              search_Reason  IN VARCHAR2,
              search_Doc     IN VARCHAR2,
              search_Verif   IN VARCHAR2,
              search_Data    IN VARCHAR2,
              search_Tags    IN VARCHAR2,
              modifAfter     IN VARCHAR2 DEFAULT NULL,
              modifBefore    IN VARCHAR2 DEFAULT NULL,
              pagenum IN NUMBER,
              pagerecs IN NUMBER,
              column_order IN VARCHAR2,
              ordertype IN VARCHAR2,
              rfCurs OUT SYS_REFCURSOR
    ) IS
    sx CLOB;
    sorder VARCHAR2(128);
    BEGIN
    /*sx:='SELECT * FROM
          table(
      nnt_search_changelogtmp.searchLog(
       entity=> :entity
      ,search_ModifBy=> :search_ModifBy
      ,search_Reason=> :search_Reason
      ,search_Doc=> :search_Doc
      ,search_Verif=> :search_Verif
      ,search_Data=> :search_Data
      ,search_Tags=> :search_Tags
      ,modifAfter=> :modifAfter ) ) ';*/
    sx :='SELECT /*+ FIRST_ROWS*/ * FROM (select /*+ FIRST_ROWS(n) */
                a.*, to_char(ROWNUM) rnum from
         (SELECT * FROM
          table(
      nnt_search_changelogtmp.searchLog(
       entity=> :entity
      ,search_ModifBy=> :search_ModifBy
      ,search_Reason=> :search_Reason
      ,search_Doc=> :search_Doc
      ,search_Verif=> :search_Verif
      ,search_Data=> :search_Data
      ,search_Tags=> :search_Tags
      ,modifAfter=> :modifAfter )
      ) ) a
      WHERE
      rownum<= ( :pagenum ) * :pagerecs )
      WHERE rnum > ( :pagenum -1) * :pagerecs ';
      IF column_order IS NULL THEN
        sorder:='';
      ELSE
        sorder := 'order by '||column_order||' '||ordertype;
      END IF;
      dbms_output.put_line(sx||sorder);


      OPEN rfCurs FOR (sx||sorder)
      USING entity, search_ModifBy, search_Reason,
              search_Doc     ,
              search_Verif   ,
              search_Data    ,
              search_Tags    ,
              modifAfter     ,
              pagenum ,
              pagerecs ,
              column_order ,
              ordertype;
    END;

END dev_piped_results;
/