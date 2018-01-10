CREATE OR REPLACE PACKAGE BODY sbxtax4.CHANGE_RECORD_DATE
AS
    io_buffer VARCHAR2(32767 CHAR) := ' ';
    v_clob CLOB;
    v_chunked_clob CLOB;
PROCEDURE Generate_change_record(
      content_type    IN VARCHAR2,
      content_consumer IN VARCHAR2,
      content_description IN VARCHAR2,
      oracle_directory IN VARCHAR2,
      overwrite_existing IN NUMBER,
      change_date_after IN DATE,
      change_date_before IN DATE,
      id_o OUT NUMBER,
      success_o OUT NUMBER)
  as
    v_change_date_after DATE := change_date_after;
    v_content_type    VARCHAR2(100 BYTE) := content_type;    --example: 'INTL' or 'US'
    v_content_version VARCHAR2(500 BYTE)  := to_char(change_date_after, 'DD-MON-YYYY')||'to'||nvl(to_char(change_date_before, 'DD-MON-YYYY'),'EOT'); --Start date is required
    v_content_consumer VARCHAR2(100 BYTE) := content_consumer; --Who is the content being sent to
    v_content_description VARCHAR2(500 BYTE) := content_description;  --Describe the content
    v_oracle_directory VARCHAR2(50 BYTE) := oracle_directory; --NULL if writing to DB only, if populated will generate XLS file to oracle directory

    --v_overwrite_existing NUMBER := overwrite_existing; --A 1 will re-create the CLOB if it already exists
    v_overwrite_existing NUMBER := 1; -- Always re-create CRAPP-3749 CRAPP 4114
    v_change_date_before DATE := nvl(change_date_before,'31-dec-2032');--default to a long time from now

    v_max_change_record_version VARCHAR2(200 BYTE);
    v_combined_versions NUMBER := 1;

    v_chunked_single_version VARCHAR2(100 BYTE);
    v_success NUMBER := 0;--start as unsuccessful
    v_id      NUMBER;

   BEGIN
    DBMS_OUTPUT.PUT_LINE('BEGIN: CHANGE_RECORD.generate_change_record');

    --delete old existing records that are very large to save DB space
    delete from A_CHANGE_RECORD where length(xml_clob) > 2000000;

    --Check for existing change record that is exactly the same, so we don't have to redo work
    BEGIN
      SELECT ID
      INTO v_id
      FROM a_change_record
      WHERE content_type      = v_content_type
      AND consumer = v_content_consumer
      and content_description = v_content_description --Look for an existing record with the same description (otherwise create a new)
      and content_version = v_content_version; --look for the date range in the content_version
      --AND nvl(v_include_multiple_updates,1) < 2;--If user gave a number of updates, then we should not find anything here (will create a duplicate but oh well
      DBMS_OUTPUT.PUT_LINE('Existing record found for requested version, A_CHANGE_RECORD.id: '||v_id);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('No existing record found for requested version.');
      v_id := NULL;
    END;
        
    IF v_id IS NULL OR (v_overwrite_existing = 1 AND v_id IS NOT NULL) THEN --It doesn't exist or the user wants to overwrite the existing

       IF v_content_consumer = 'CHECKPOINT' THEN
          DBMS_OUTPUT.PUT_LINE('Content consumer is CHECKPOINT, creating simle rates file.');
          create_simple_rates_file(v_content_type, v_content_version, v_change_date_after, v_change_date_before);
        ELSE
          DBMS_OUTPUT.PUT_LINE('Content consumer: '||v_content_consumer);
          DBMS_OUTPUT.PUT_LINE('Creating summary with start date from:'||v_change_date_after||' to '|| v_change_date_before);
          create_full_change_clob(v_content_type, v_content_version, v_change_date_after, v_change_date_before);
        END IF;--normal vs CHECKPOINT
  
 
        --Update or insert based on current v_id value
        IF v_id IS NULL THEN
          INSERT --INSERT CLOB and info INTO CHANGE RECORD
          INTO A_CHANGE_RECORD   (          ID,          CONTENT_TYPE,          CONTENT_VERSION,          CONSUMER,          DESCRIPTION,          FILE_EXT,          XML_CLOB  , CREATION_DATE      )
          VALUES  ( (SELECT NVL(MAX(id)+1,1) FROM A_CHANGE_RECORD),  v_content_type,   v_content_version,   v_content_consumer,   v_content_description,   'xls',       v_clob  , SYSTIMESTAMP    ) RETURNING ID INTO v_id;
        ELSE
          DBMS_OUTPUT.PUT_LINE('Overwriting existing clob with newly generated one.');
          UPDATE A_CHANGE_RECORD
          SET XML_CLOB = v_clob, LAST_UPDATE_DATE = SYSTIMESTAMP
          WHERE ID = v_id;
        END IF;
        
    END IF;--Existing record or wanting to overwrite

    --Will only write out the chunked/multiple file or single file, not all of the singles created when chunking
    IF v_oracle_directory IS NOT NULL THEN --if directory is given, write the clob out as a file to it
        DBMS_OUTPUT.PUT_LINE('Generating file in oracle_directory:'||v_oracle_directory);
        IF v_clob IS NULL THEN --if the clob was not just built, get the existing
          SELECT XML_CLOB
          INTO v_clob
          FROM A_CHANGE_RECORD
          WHERE ID = v_id;
        END IF;


        --Only works in 11g, write clob 2 file
        DBMS_XSLPROCESSOR.clob2file(v_clob, v_oracle_directory, v_content_type||'-'||v_content_version||'-'||v_content_consumer||'.xls');
        DBMS_OUTPUT.PUT_LINE('File:'||v_content_type||'-'||v_content_version||'-'||v_content_consumer||'.xls'||' Created.');
    END IF; --if oracle_directory is given

    id_o := v_id;--will only return the most recent ID gathered


    v_success := 1;
    success_o := v_success;
    DBMS_OUTPUT.PUT_LINE('END: CHANGE_RECORD.generate_change_record, completed successfully.');
  END Generate_Change_record;

  --replace DBMS_LOB.append with append tex so that it is properly buffered for smaller values
  PROCEDURE append_text(io_clob    IN OUT NOCOPY CLOB
                      , io_buffer  IN OUT NOCOPY VARCHAR2
                      , i_text     IN            VARCHAR2) IS
  BEGIN
    io_buffer := io_buffer || i_text;
  EXCEPTION
    WHEN VALUE_ERROR THEN
      IF io_clob IS NULL THEN
        io_clob := io_buffer;
      ELSE
        DBMS_LOB.writeappend(io_clob
                           , LENGTH(io_buffer)
                           , io_buffer);
        io_buffer := i_text;
      END IF;
  END append_text;


  PROCEDURE run_query
    (
      p_sql IN VARCHAR2
    )
  AS
    v_change_type VARCHAR2(4000);
    v_v_val     VARCHAR2(4000);
    v_v_val_o   VARCHAR2(4000);
    v_n_val     NUMBER;
    v_n_val_o   NUMBER;
    v_d_val     DATE;
    v_d_val_o   DATE;
    v_ret       NUMBER;
    c           NUMBER;
    d           NUMBER;
    col_cnt     INTEGER;
    f           BOOLEAN;
    rec_tab     DBMS_SQL.DESC_TAB;
    col_num     NUMBER;
  BEGIN
    c := DBMS_SQL.OPEN_CURSOR;
    -- parse the SQL statement
    DBMS_OUTPUT.PUT_LINE('SQL START:'||SYSTIMESTAMP);
    DBMS_SQL.PARSE(c, p_sql, DBMS_SQL.NATIVE);
    -- start execution of the SQL statement
    d := DBMS_SQL.EXECUTE(c);
    DBMS_OUTPUT.PUT_LINE('SQL END:'||SYSTIMESTAMP);
    -- get a description of the returned columns
    DBMS_SQL.DESCRIBE_COLUMNS(c, col_cnt, rec_tab);
    -- bind variables to columns
    FOR j in 1..col_cnt
    LOOP
      CASE rec_tab(j).col_type
        WHEN 1 THEN DBMS_SQL.DEFINE_COLUMN(c,j,v_v_val,4000);
        WHEN 2 THEN DBMS_SQL.DEFINE_COLUMN(c,j,v_n_val);
        WHEN 12 THEN DBMS_SQL.DEFINE_COLUMN(c,j,v_d_val);
      ELSE
        DBMS_SQL.DEFINE_COLUMN(c,j,v_v_val,4000);
      END CASE;
    END LOOP;
    -- Output the column headers
    append_text(v_clob,io_buffer, '<Row>');
    FOR j in 1..col_cnt
    LOOP
      if instr(rec_tab(j).col_name, 'UPDATED') <> 0 then
        append_text(v_clob,io_buffer, '<Cell ss:StyleID="Highlight">');
        DBMS_OUTPUT.PUT_LINE('Column to highlight:'||rec_tab(j).col_name);
      else
        append_text(v_clob,io_buffer, '<Cell>');
      end if;
      append_text(v_clob,io_buffer, '<Data ss:Type="String">'||rec_tab(j).col_name||'</Data>');
      append_text(v_clob,io_buffer, '</Cell>');
    END LOOP;
    append_text(v_clob,io_buffer, '</Row>');
    -- Output the data
    DBMS_OUTPUT.PUT_LINE('colum/header loop finished:'||SYSTIMESTAMP);
    LOOP
      v_ret := DBMS_SQL.FETCH_ROWS(c);
      EXIT WHEN v_ret = 0;
      append_text(v_clob,io_buffer, '<Row>');
      FOR j in 1..col_cnt
      LOOP
        CASE rec_tab(j).col_type
          WHEN 1 THEN DBMS_SQL.COLUMN_VALUE(c,j,v_v_val);
                      IF (j>1 AND REPLACE(rec_tab(j).col_name,'UPDATED ') = REPLACE(rec_tab(j-1).col_name,'PREVIOUS ') AND rec_tab(j).col_name != 'VERSION') THEN
                        DBMS_SQL.COLUMN_VALUE(c,(j-1),v_v_val_o);--GET PRIOR COLUMN VALUE
                        DBMS_SQL.COLUMN_VALUE(c, 1, v_change_type);--GET CHANGE TYPE
                        IF (NVL(v_v_val_o,'XXX') != NVL(v_v_val,'XXX') AND v_change_type = 'UPDATED') THEN --IF THEY ARE DIFFERENT
                          append_text(v_clob,io_buffer, '<Cell ss:StyleID="Highlight">');
                                      append_text(v_clob,io_buffer, '<Data ss:Type="String"><![CDATA['||v_v_val||']]></Data>');--change the color
                        ELSE -- THEY ARE THE SAME
                          append_text(v_clob,io_buffer, '<Cell>');
                          append_text(v_clob,io_buffer, '<Data ss:Type="String"><![CDATA['||v_v_val||']]></Data>');
                        END IF;
                      ELSE --DON'T COMPARE
                        append_text(v_clob,io_buffer, '<Cell>');
                        append_text(v_clob,io_buffer, '<Data ss:Type="String"><![CDATA['||v_v_val||']]></Data>');
                      END IF;
                      append_text(v_clob,io_buffer, '</Cell>');
          WHEN 2 THEN DBMS_SQL.COLUMN_VALUE(c,j,v_n_val);
                        IF (j>1 AND REPLACE(rec_tab(j).col_name,'UPDATED ') = REPLACE(rec_tab(j-1).col_name,'PREVIOUS ')) THEN
                          DBMS_SQL.COLUMN_VALUE(c,(j-1),v_n_val_o);--GET PRIOR COLUMN VALUE
                          DBMS_SQL.COLUMN_VALUE(c, 1, v_change_type);--GET CHANGE TYPE
                          IF (NVL(v_n_val_o,9999999999) != NVL(v_n_val,9999999999) AND v_change_type = 'UPDATED') THEN --IF THEY ARE DIFFERENT
                            --Special case for flat fee
                            append_text(v_clob,io_buffer, '<Cell ss:StyleID="Highlight">');
                            IF v_n_val IS NULL THEN
                              append_text(v_clob,io_buffer, '<Data ss:Type="String"></Data>');
                            ELSE
                               append_text(v_clob,io_buffer, '<Data ss:Type="Number">'||to_char(v_n_val)||'</Data>');--change the color
                            END IF;
                          ELSE -- THEY ARE THE SAME
                            append_text(v_clob,io_buffer, '<Cell>');
                            IF v_n_val IS NULL THEN
                              append_text(v_clob,io_buffer, '<Data ss:Type="String"></Data>');
                            ELSE
                              append_text(v_clob,io_buffer, '<Data ss:Type="Number">'||to_char(v_n_val)||'</Data>');
                            END IF;
                          END IF;
                        ELSE --DON'T COMPARE
                          append_text(v_clob,io_buffer, '<Cell>');
                          IF v_n_val IS NULL THEN
                            append_text(v_clob,io_buffer, '<Data ss:Type="String"></Data>');
                          ELSE
                            append_text(v_clob,io_buffer, '<Data ss:Type="Number">'||to_char(v_n_val)||'</Data>');
                          END IF;
                        END IF;

                        --append_text(v_clob,io_buffer, '<Data ss:Type="Number">'||to_char(v_n_val)||'</Data>');

                      append_text(v_clob,io_buffer, '</Cell>');
          WHEN 12 THEN DBMS_SQL.COLUMN_VALUE(c,j,v_d_val);
                       IF (j>1 AND REPLACE(rec_tab(j).col_name,'UPDATED ') = REPLACE(rec_tab(j-1).col_name,'PREVIOUS ')) THEN
                          DBMS_SQL.COLUMN_VALUE(c,(j-1),v_d_val_o);--GET PRIOR COLUMN VALUE
                          DBMS_SQL.COLUMN_VALUE(c, 1, v_change_type);--GET CHANGE TYPE
                          IF (NVL(v_d_val_o,'01-jan-2099') != NVL(v_d_val,'01-jan-2099') AND v_change_type = 'UPDATED') THEN --IF THEY ARE DIFFERENT
                            IF v_d_val IS NULL THEN
                              append_text(v_clob,io_buffer, '<Cell ss:StyleID="Highlight">');
                              append_text(v_clob,io_buffer, '<Data ss:Type="String"></Data>');
                            ELSE
                              append_text(v_clob,io_buffer, '<Cell ss:StyleID="Highlight" StyleID="OracleDate">');
                              append_text(v_clob,io_buffer, '<Data ss:Type="String">'||to_char(v_d_val,'YYYY-MM-DD')||'</Data>');--change the color
                            END IF;
                          ELSE -- THEY ARE THE SAME
                             IF v_d_val IS NULL THEN
                              append_text(v_clob,io_buffer, '<Cell>');
                              append_text(v_clob,io_buffer, '<Data ss:Type="String"></Data>');
                            ELSE
                              append_text(v_clob,io_buffer, '<Cell StyleID="OracleDate">');
                              append_text(v_clob,io_buffer, '<Data ss:Type="String">'||to_char(v_d_val,'YYYY-MM-DD')||'</Data>');
                            END IF;
                          END IF;
                        ELSE
                          IF v_d_val IS NULL THEN
                            append_text(v_clob,io_buffer, '<Cell>');
                            append_text(v_clob,io_buffer, '<Data ss:Type="String"></Data>');
                          ELSE
                            append_text(v_clob,io_buffer, '<Cell StyleID="OracleDate">');
                            append_text(v_clob,io_buffer, '<Data ss:Type="String">'||to_char(v_d_val,'YYYY-MM-DD')||'</Data>');
                          END IF;
                        END IF;
                      append_text(v_clob,io_buffer, '</Cell>');
        ELSE
          DBMS_SQL.COLUMN_VALUE(c,j,v_v_val);
          append_text(v_clob,io_buffer, '<Cell>');
          append_text(v_clob,io_buffer, '<Data ss:Type="String"><![CDATA['||v_v_val||']]></Data>');
          append_text(v_clob,io_buffer, '</Cell>');
        END CASE;
      END LOOP;
      append_text(v_clob,io_buffer, '</Row>
      ');--extra line break character
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('XML BUILD END:'||SYSTIMESTAMP);
    DBMS_SQL.CLOSE_CURSOR(c);
  END run_query;
  
  PROCEDURE start_workbook
  AS
  BEGIN
    --append_text(v_clob,io_buffer, '<?xml version="1.0"?>');
      v_clob := '<?xml version="1.0"?>';
    io_buffer := NULL;
    append_text(v_clob,io_buffer, '<?mso-application progid="Excel.Sheet"?>');
    append_text(v_clob,io_buffer, '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
    xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:html="http://www.w3.org/TR/REC-html40">
 ');--extra line break character
  END start_workbook;
  
  PROCEDURE end_workbook
  AS
  BEGIN
    append_text(v_clob,io_buffer, '</Workbook>');
  END end_workbook;
  
  PROCEDURE start_worksheet
    (
      p_sheetname IN VARCHAR2
    )
  AS
  BEGIN
    append_text(v_clob,io_buffer, '<Worksheet ss:Name="'||p_sheetname||'">');
    append_text(v_clob,io_buffer, '<Table>');
  END start_worksheet;
  
  PROCEDURE end_worksheet
  AS
  BEGIN
    append_text(v_clob,io_buffer, '</Table>');
    append_text(v_clob,io_buffer, '</Worksheet>
    ');--extra line break character
  END end_worksheet;
  
  PROCEDURE set_date_style
  AS
  BEGIN
        append_text(v_clob,io_buffer, '<Styles>');
    append_text(v_clob,io_buffer, '<Style ss:ID="OracleDate">');
    --append_text(v_clob,io_buffer, '<ss:NumberFormat ss:Format="dd/mm/yyyy\ hh:mm:ss"/>');
    append_text(v_clob,io_buffer, '<NumberFormat ss:Format="dd/mm/yyyy"/>');
    append_text(v_clob,io_buffer, '</Style>');
    append_text(v_clob,io_buffer, '<Style ss:ID="Highlight">');
    append_text(v_clob,io_buffer, '<Interior ss:Color="#FFFF99" ss:Pattern="Solid"/>');
     append_text(v_clob,io_buffer, '</Style>');
    append_text(v_clob,io_buffer, '</Styles>
    ');--extra line break character
  END set_date_style;

  PROCEDURE create_full_change_clob(v_content_type IN OUT VARCHAR2, v_content_version IN OUT VARCHAR2, v_change_date_after IN OUT DATE, v_change_date_before IN OUT DATE)
  AS
  BEGIN
    start_workbook;
    set_date_style;
    start_worksheet('SUMMARY');
    IF v_content_type = 'US' THEN
        run_query('select COALESCE(AA_STAT.NAME,AR_STAT.NAME,CA_STAT.NAME,AO_STAT.NAME,ARU_STAT.NAME,ARQ_STAT.NAME) "STATE", nvl(AA_STAT.AUTHORITY_CHANGES,0) "AUTHORITIES AFFECTED", nvl(CA_STAT.AUTHORITY_CHANGES,0) "CONTRIBUTING AUTHS AFFECTED", nvl(AO_STAT.AUTHORITY_CHANGES,0) "AUTHORITY OPTIONS AFFECTED", nvl(AR_STAT.RATE_CHANGES,0) "RATES AFFECTED", nvl(ARU_STAT.RULE_CHANGES,0) "RULES AFFECTED", nvl(ARQ_STAT.RULE_QUALIFIER_CHANGES,0) "RULE QUALIFIERS AFFECTED"
          from (
          select SUBSTR(A.NAME,0,2) "NAME", COUNT(distinct a.name||r.rate_code) "RATE_CHANGES"
            from a_merchants m
            INNER JOIN TB_AUTHORITIES A ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = A.MERCHANT_ID)
            INNER JOIN A_RATES R ON (A.AUTHORITY_ID =  COALESCE(R.AUTHORITY_ID,R.AUTHORITY_ID_O))
            where r.CHANGE_DATE > '''||v_change_date_after||'''
            and r.CHANGE_DATE < '''||v_change_date_before||'''
            AND M.NAME  = ''Sabrix US Tax Data''
            GROUP BY  SUBSTR(A.NAME,0,2)
         ) "AR_STAT"
          FULL OUTER JOIN (
              select SUBSTR(TA.NAME,0,2) "NAME", COUNT(distinct Ta.name) "AUTHORITY_CHANGES"
              FROM A_MERCHANTS M
              JOIN TB_AUTHORITIES TA ON (COALESCE(M.MERCHANT_ID,M.MERCHANT_ID_O) = TA.MERCHANT_ID)
              LEFT OUTER JOIN A_AUTHORITIES A ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = coalesce(A.MERCHANT_ID,A.MERCHANT_ID_O) AND TA.AUTHORITY_ID = COALESCE(A.AUTHORITY_ID,A.AUTHORITY_ID_O))
              where a.CHANGE_DATE > '''||v_change_date_after||''' AND A.CHANGE_DATE < '''||v_change_date_before||'''
              AND M.NAME  = ''Sabrix US Tax Data''
              GROUP BY SUBSTR(TA.NAME,0,2)
          ) AA_STAT ON (AA_STAT.NAME = AR_STAT.NAME)
          FULL OUTER JOIN (
              select SUBSTR(TA.NAME,0,2) "NAME", COUNT(distinct Ta.name) "AUTHORITY_CHANGES"
              FROM A_MERCHANTS M
              JOIN TB_AUTHORITIES TA ON (COALESCE(M.MERCHANT_ID,M.MERCHANT_ID_O) = TA.MERCHANT_ID)
              LEFT OUTER JOIN A_AUTHORITY_REQUIREMENTS AR ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = coalesce(AR.MERCHANT_ID,AR.MERCHANT_ID_O) and TA.AUTHORITY_ID = COALESCE(AR.AUTHORITY_ID,AR.AUTHORITY_ID_O))
               where aR.CHANGE_DATE > '''||v_change_date_after||''' AND AR.CHANGE_DATE < '''||v_change_date_before||'''
              AND M.NAME  = ''Sabrix US Tax Data''
              GROUP BY SUBSTR(TA.NAME,0,2)
          ) AO_STAT ON (AO_STAT.NAME = COALESCE(AR_STAT.NAME,AA_STAT.NAME))
          FULL OUTER JOIN (
              select SUBSTR(TA.NAME,0,2) "NAME", COUNT(distinct Ta.name) "AUTHORITY_CHANGES"
              FROM A_MERCHANTS M
              JOIN TB_AUTHORITIES TA ON (COALESCE(M.MERCHANT_ID,M.MERCHANT_ID_O) = TA.MERCHANT_ID)
              left outer JOIN A_CONTRIBUTING_AUTHORITIES CA ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = coalesce(CA.MERCHANT_ID,CA.MERCHANT_ID_O) AND 
              (TA.AUTHORITY_ID = COALESCE(CA.AUTHORITY_ID,CA.AUTHORITY_ID_O) OR TA.AUTHORITY_ID = COALESCE(CA.THIS_AUTHORITY_ID,CA.THIS_AUTHORITY_ID_O)))
              where Ca.CHANGE_DATE > '''||v_change_date_after||''' AND cA.CHANGE_DATE < '''||v_change_date_before||'''
              AND M.NAME  = ''Sabrix US Tax Data''
              GROUP BY SUBSTR(TA.NAME,0,2)
          ) CA_STAT ON (CA_STAT.NAME = COALESCE(AR_STAT.NAME,AA_STAT.NAME,AO_STAT.NAME))
          FULL OUTER JOIN (
            select SUBSTR(A.NAME,0,2) "NAME", COUNT(distinct a.name||r.rule_order) "RULE_CHANGES"
            from a_merchants m
            INNER JOIN TB_AUTHORITIES A ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = A.MERCHANT_ID)
            INNER JOIN A_RULES R ON (A.AUTHORITY_ID =  COALESCE(R.AUTHORITY_ID,R.AUTHORITY_ID_O) AND coalesce(R.MERCHANT_ID,R.MERCHANT_ID_O) = coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O))
            where r.CHANGE_DATE > '''||v_change_date_after||'''
            and r.CHANGE_DATE < '''||v_change_date_before||'''
            AND M.NAME  = ''Sabrix US Tax Data''
            GROUP BY  SUBSTR(A.NAME,0,2)
          ) ARU_STAT  ON (ARU_STAT.NAME = COALESCE(AR_STAT.NAME,AA_STAT.NAME,AO_STAT.NAME,CA_STAT.NAME))
          FULL OUTER JOIN (
            SELECT SUBSTR(A.NAME,0,2) "NAME", COUNT(distinct a.name||rQ.RULE_QUALIFIER_ID) "RULE_QUALIFIER_CHANGES"
            from a_merchants m
            INNER JOIN TB_AUTHORITIES A ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = A.MERCHANT_ID)
            INNER JOIN A_RULES RU ON (A.AUTHORITY_ID = COALESCE(RU.AUTHORITY_ID,RU.AUTHORITY_ID_O) AND COALESCE(RU.MERCHANT_ID,RU.MERCHANT_ID_O) = A.MERCHANT_ID)
            INNER JOIN A_RULE_QUALIFIERS RQ ON (COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) = COALESCE(RU.RULE_ID,RU.RULE_ID_O))
            where COALESCE(rQ.CHANGE_DATE, RU.CHANGE_DATE) > '''||v_change_date_after||'''
            and COALESCE(rQ.CHANGE_DATE, RU.CHANGE_DATE) < '''||v_change_date_before||'''
            AND M.NAME  = ''Sabrix US Tax Data''
            GROUP BY  SUBSTR(A.NAME,0,2)
          ) ARQ_STAT ON (ARQ_STAT.NAME = COALESCE(AR_STAT.NAME,AA_STAT.NAME,AO_STAT.NAME,CA_STAT.NAME,ARU_STAT.NAME))
          ORDER BY  COALESCE(AA_STAT.NAME,AR_STAT.NAME,AO_STAT.NAME, CA_STAT.NAME, ARU_STAT.NAME, ARQ_STAT.NAME)'
        );
        
    ELSE
        run_query('
select  COALESCE(AA_STAT.NAME,AR_STAT.NAME,AO_STAT.NAME, CA_STAT.NAME, ARU_STAT.NAME,ARQ_STAT.NAME) "AUTHORITIES", nvl(AA_STAT.AUTHORITY_CHANGES,0) "AUTHORITIES AFFECTED", nvl(CA_STAT.AUTHORITY_CHANGES,0) "CONTRIBUTING AUTHS AFFECTED", nvl(AO_STAT.AUTHORITY_CHANGES,0) "AUTHORITY OPTIONS AFFECTED", nvl(AR_STAT.RATE_CHANGES,0) "RATES AFFECTED", nvl(ARU_STAT.RULE_CHANGES,0) "RULES AFFECTED", nvl(ARQ_STAT.RULE_QUALIFIER_CHANGES,0) "RULE QUALIFIERS AFFECTED"
          from (
          select A.NAME "NAME", COUNT(distinct a.name||r.rate_code) "RATE_CHANGES"
            from a_merchants m
            INNER JOIN TB_AUTHORITIES A ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = A.MERCHANT_ID)
            INNER JOIN A_RATES R ON (A.AUTHORITY_ID =  COALESCE(R.AUTHORITY_ID,R.AUTHORITY_ID_O))
            where r.CHANGE_DATE > '''||v_change_date_after||'''
            and r.CHANGE_DATE < '''||v_change_date_before||'''
            AND M.NAME  = ''Sabrix INTL Tax Data''
            GROUP BY  A.NAME
         ) "AR_STAT"
         FULL OUTER JOIN (
               select TA.NAME "NAME", COUNT(distinct Ta.name) "AUTHORITY_CHANGES"
              FROM A_MERCHANTS M
              JOIN TB_AUTHORITIES TA ON (COALESCE(M.MERCHANT_ID,M.MERCHANT_ID_O) = TA.MERCHANT_ID)
              LEFT OUTER JOIN A_AUTHORITIES A ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = coalesce(A.MERCHANT_ID,A.MERCHANT_ID_O) AND TA.AUTHORITY_ID = COALESCE(A.AUTHORITY_ID,A.AUTHORITY_ID_O))
              where a.CHANGE_DATE > '''||v_change_date_after||''' AND A.CHANGE_DATE < '''||v_change_date_before||'''
              AND M.NAME  = ''Sabrix INTL Tax Data''
              GROUP BY TA.NAME
        ) AA_STAT ON (AR_STAT.NAME = AA_STAT.NAME)
        FULL OUTER JOIN (
              select TA.NAME "NAME", COUNT(distinct Ta.name) "AUTHORITY_CHANGES"
              FROM A_MERCHANTS M
              JOIN TB_AUTHORITIES TA ON (COALESCE(M.MERCHANT_ID,M.MERCHANT_ID_O) = TA.MERCHANT_ID)
              LEFT OUTER JOIN A_AUTHORITY_REQUIREMENTS AR ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = coalesce(AR.MERCHANT_ID,AR.MERCHANT_ID_O) and TA.AUTHORITY_ID = COALESCE(AR.AUTHORITY_ID,AR.AUTHORITY_ID_O))
               where aR.CHANGE_DATE > '''||v_change_date_after||''' AND AR.CHANGE_DATE < '''||v_change_date_before||'''
              AND M.NAME  = ''Sabrix INTL Tax Data''
              GROUP BY TA.NAME
      ) AO_STAT ON (AO_STAT.NAME = COALESCE(AR_STAT.NAME,AA_STAT.NAME))
              FULL OUTER JOIN (
              select TA.NAME "NAME", COUNT(distinct Ta.name) "AUTHORITY_CHANGES"
              FROM A_MERCHANTS M
              JOIN TB_AUTHORITIES TA ON (COALESCE(M.MERCHANT_ID,M.MERCHANT_ID_O) = TA.MERCHANT_ID)
              left outer JOIN A_CONTRIBUTING_AUTHORITIES CA ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = coalesce(CA.MERCHANT_ID,CA.MERCHANT_ID_O) AND 
              (TA.AUTHORITY_ID = COALESCE(CA.AUTHORITY_ID,CA.AUTHORITY_ID_O) OR TA.AUTHORITY_ID = COALESCE(CA.THIS_AUTHORITY_ID,CA.THIS_AUTHORITY_ID_O)))
              where Ca.CHANGE_DATE > '''||v_change_date_after||''' AND cA.CHANGE_DATE < '''||v_change_date_before||'''
              AND M.NAME  = ''Sabrix INTL Tax Data''
              GROUP BY TA.NAME
          ) CA_STAT ON (CA_STAT.NAME = COALESCE(AR_STAT.NAME,AA_STAT.NAME,AO_STAT.NAME))
          FULL OUTER JOIN (
            select A.NAME "NAME", COUNT(distinct a.name||r.rule_order) "RULE_CHANGES"
            from a_merchants m
            INNER JOIN TB_AUTHORITIES A ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = A.MERCHANT_ID)
            INNER JOIN A_RULES R ON (A.AUTHORITY_ID =  COALESCE(R.AUTHORITY_ID,R.AUTHORITY_ID_O) AND coalesce(R.MERCHANT_ID,R.MERCHANT_ID_O) = coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O))
            where r.CHANGE_DATE > '''||v_change_date_after||'''
            and r.CHANGE_DATE < '''||v_change_date_before||'''
            AND M.NAME  = ''Sabrix INTL Tax Data''
            GROUP BY  A.NAME
          ) ARU_STAT  ON (ARU_STAT.NAME = COALESCE(AR_STAT.NAME,AA_STAT.NAME,AO_STAT.NAME,CA_STAT.NAME))
          FULL OUTER JOIN (
            SELECT A.NAME "NAME", COUNT(distinct a.name||rQ.RULE_QUALIFIER_ID) "RULE_QUALIFIER_CHANGES"
            from a_merchants m
            INNER JOIN TB_AUTHORITIES A ON (coalesce(M.MERCHANT_ID,M.MERCHANT_ID_O) = A.MERCHANT_ID)
            INNER JOIN A_RULES RU ON (A.AUTHORITY_ID = COALESCE(RU.AUTHORITY_ID,RU.AUTHORITY_ID_O) AND COALESCE(RU.MERCHANT_ID,RU.MERCHANT_ID_O) = A.MERCHANT_ID)
            INNER JOIN A_RULE_QUALIFIERS RQ ON (COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) = COALESCE(RU.RULE_ID,RU.RULE_ID_O))
            where COALESCE(rQ.CHANGE_DATE, RU.CHANGE_DATE) > '''||v_change_date_after||'''
            and COALESCE(rQ.CHANGE_DATE, RU.CHANGE_DATE) < '''||v_change_date_before||'''
            AND M.NAME  = ''Sabrix INTL Tax Data''
            GROUP BY A.NAME
          ) ARQ_STAT ON (ARQ_STAT.NAME = COALESCE(AR_STAT.NAME,AA_STAT.NAME,AO_STAT.NAME,CA_STAT.NAME,ARU_STAT.NAME))
          ORDER BY  COALESCE(AA_STAT.NAME,AR_STAT.NAME,AO_STAT.NAME,CA_STAT.NAME,ARU_STAT.NAME,ARQ_STAT.NAME)'
        );    
        
    END IF;
    DBMS_OUTPUT.PUT_LINE('CHANGE SUMMARY COMPLETE');
    end_worksheet;
    start_worksheet('AUTHORITIES');
    run_query('select a.change_type "OPERATION TYPE",
      CHANGE_VERSION "VERSION",
      A.CHANGE_DATE "CHANGE DATE",
      A.NAME_O "PREVIOUS NAME",
      a.NAME "UPDATED NAME",
      A.OFFICIAL_NAME_O "PREVIOUS OFFICIAL NAME",
      A.OFFICIAL_NAME "UPDATED OFFICIAL NAME",
      A.AUTHORITY_CATEGORY_O "PREVIOUS AUTHORITY CATEGORY",
      A.AUTHORITY_CATEGORY "UPDATED AUTHORITY CATEGORY",
      A.INVOICE_DESCRIPTION_O "PREVIOUS INVOICE DESCRIPTION",
      A.INVOICE_DESCRIPTION "UPDATED INVOICE DESCRIPTION",
      A.REGION_CODE_O "PREVIOUS AUTHORITY FIPS CODE",
      A.REGION_CODE "UPDATED AUTHORITY FIPS CODE",
      A.DESCRIPTION_O "PREVIOUS DESCRIPTION",
      A.DESCRIPTION "UPDATED DESCRIPTION",
      ATO.NAME "PREVIOUS AUTHORITY TYPE",
      AT.NAME "UPDATED AUTHORITY TYPE",
      A.REGISTRATION_MASK_O "PREVIOUS REGISTRATION MASK",
      a.REGISTRATION_MASK "UPDATED REGISTRATION MASK",
      A.SIMPLE_REGISTRATION_MASK_O "PREVIOUS SIMPLE REG MASK",
      a.SIMPLE_REGISTRATION_MASK "UPDATED SIMPLE REG MASK",
      A.LOCATION_CODE_O "PREVIOUS LOCATION CODE",
      a.LOCATION_CODE "UPDATED LOCATION CODE",
      A.DISTANCE_SALES_THRESHOLD_O "PREVIOUS DISTANCE THRESHOLD",
      A.DISTANCE_SALES_THRESHOLD "UPDATED DISTANCE THRESHOLD",
      A.CONTENT_TYPE_O "PREVIOUS CONTENT TYPE",
      A.CONTENT_TYPE "UPDATED CONTENT TYPE",
      PGO.NAME "PREVIOUS PRODUCT GROUP",
      PG.NAME "UPDATED PRODUCT GROUP",
      ZLO.NAME "PREVIOUS ADMIN LEVEL",
      ZL.NAME "UPDATED ADMIN LEVEL",
      ZEO.NAME "PREVIOUS EFFECTIVE LEVEL",
      ZE.NAME "UPDATED EFFECTIVE LEVEL",
      A.UUID_O "PREVIOUS UUID",
      A.UUID "UUID"
      from A_authorities A, TB_ZONE_LEVELS ZL, TB_ZONE_LEVELS ZE, TB_AUTHORITY_TYPES AT, TB_ZONE_LEVELS ZLO,
      TB_ZONE_LEVELS ZEO, TB_AUTHORITY_TYPES ATO, TB_MERCHANTS M, TB_PRODUCT_GROUPS PG, TB_PRODUCT_GROUPS PGO
      WHERE A.CHANGE_DATE > '''||v_change_date_after||'''
      AND A.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.MERCHANT_ID = coalesce(A.MERCHANT_ID,A.MERCHANT_ID_O)
      AND M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      AND A.ADMIN_ZONE_LEVEL_ID = ZL.ZONE_LEVEL_ID(+)
      AND A.EFFECTIVE_ZONE_LEVEL_ID = ZE.ZONE_LEVEL_ID(+)
      AND A.AUTHORITY_TYPE_ID = AT.AUTHORITY_TYPE_ID(+)
      AND A.AUTHORITY_TYPE_ID_O = ATO.AUTHORITY_TYPE_ID(+)
      AND A.EFFECTIVE_ZONE_LEVEL_ID_O = ZEO.ZONE_LEVEL_ID(+)
      AND A.ADMIN_ZONE_LEVEL_ID_O = ZLO.ZONE_LEVEL_ID(+)
      AND A.PRODUCT_GROUP_ID = PG.PRODUCT_GROUP_ID(+)
      AND A.PRODUCT_GROUP_ID_O = PGO.PRODUCT_GROUP_ID(+)
      ORDER BY A.CHANGE_VERSION, A.NAME, A.CHANGE_TYPE');
      DBMS_OUTPUT.PUT_LINE('AUTHORITY COMPLETE');
    end_worksheet;
    start_worksheet('CONTRIBUTING AUTHORITIES');
    run_query('SELECT CA.CHANGE_TYPE "OPERATION TYPE",
      CHANGE_VERSION "VERSION",
      CA.CHANGE_DATE "CHANGE DATE",
      A_FROM_O.NAME "PREVIOUS FROM AUTHORITY",
      A_FROM.NAME "UPDATED FROM AUTHORITY",
      A_TO_O.NAME "PREVIOUS TO AUTHORITY",
      A_TO.NAME "UPDATED TO AUTHORITY",
      CA.BASIS_PERCENT_O "PREVIOUS BASIS PERCENT",
      CA.BASIS_PERCENT "UPDATED BASIS PERCENT",
      CA.START_DATE_O "PREVIOUS START DATE",
      CA.START_DATE "UPDATED START DATE",
      CA.END_DATE_O "PREVIOUS END DATE",
      CA.END_DATE "UPDATED END DATE"
      FROM A_CONTRIBUTING_AUTHORITIES CA, TB_MERCHANTS M, TB_AUTHORITIES A_FROM, TB_AUTHORITIES A_TO, TB_AUTHORITIES A_FROM_O, TB_AUTHORITIES A_TO_O
      WHERE CA.CHANGE_DATE > '''||v_change_date_after||'''
      AND CA.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.MERCHANT_ID = coalesce(CA.MERCHANT_ID,CA.MERCHANT_ID_O)
      AND M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      AND CA.AUTHORITY_ID_O = A_TO_O.AUTHORITY_ID(+)
      AND CA.AUTHORITY_ID = A_TO.AUTHORITY_ID(+)
      AND CA.THIS_AUTHORITY_ID = A_FROM.AUTHORITY_ID(+)
      AND CA.THIS_AUTHORITY_ID_O = A_FROM_O.AUTHORITY_ID(+)
      ORDER BY CA.CHANGE_VERSION, A_FROM.NAME, A_TO.NAME');
      DBMS_OUTPUT.PUT_LINE('CONTRIBUTING AUTHORITY COMPLETE');
    end_worksheet;
    start_worksheet('AUTHORITY OPTIONS');
    run_query('SELECT AR.CHANGE_TYPE "OPERATION TYPE",
      CHANGE_VERSION "VERSION",
      AR.CHANGE_DATE "CHANGE DATE",
      A.NAME "AUTHORITY",
      LO.DESCRIPTION "PREVIOUS DESCRIPTION",
      L.DESCRIPTION "UPDATED DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_COND'' AND CODE = AR.CONDITION_O) "PREVIOUS CONDITION DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_COND'' AND CODE = AR.CONDITION) "UPDATED CONDITION DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_VALUE'' AND CODE = AR.VALUE_O) "PREVIOUS VALUE DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_VALUE'' AND CODE = AR.VALUE) "UPDATED VALUE DESCRIPTION",
      AR.START_DATE_O "PREVIOUS START DATE",
      AR.START_DATE "UPDATED START DATE",
      AR.END_DATE_O "PREVIOUS END DATE",
      AR.END_DATE "UPDATED END DATE"
      FROM A_AUTHORITY_REQUIREMENTS AR, TB_MERCHANTS M, TB_AUTHORITIES A, TB_LOOKUPS L, TB_LOOKUPS LO
      WHERE AR.CHANGE_DATE > '''||v_change_date_after||'''
      AND AR.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.MERCHANT_ID = coalesce(AR.MERCHANT_ID,AR.MERCHANT_ID_O)
      AND M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      AND COALESCE(AR.AUTHORITY_ID,AR.AUTHORITY_ID_O) = A.AUTHORITY_ID
      AND AR.NAME_O = LO.CODE(+)
      AND nvl(LO.CODE_GROUP,''AUTH_REQ_NAME'') = ''AUTH_REQ_NAME''
      AND AR.NAME = L.CODE(+)
      AND L.CODE_GROUP = ''AUTH_REQ_NAME''
      ORDER BY AR.CHANGE_VERSION, A.NAME, AR.CHANGE_TYPE
    ');
    DBMS_OUTPUT.PUT_LINE('AUTHORITY OPITONS COMPLETE');
    end_worksheet;
    start_worksheet('AUTHORITY SPECIFIC MESSAGES');
      run_query('SELECT AE.CHANGE_TYPE "OPERATION TYPE",
      CHANGE_VERSION "VERSION",
      AO.NAME "PREVIOUS AUTHORITY NAME",
      A.NAME "UPDATED AUTHORITY NAME",
      AE.ERROR_NUM_O "PREVIOUS ERROR NUMBER",
      AE.ERROR_NUM "UPDATED ERROR NUMBER",
      AE.ERROR_SEVERITY_O "PREVIOUS ERROR SEVERITY",
      AE.ERROR_SEVERITY "UPDATED ERROR SEVERITY",
      AE.TITLE_O "PREVIOUS TITLE",
       AE.TITLE "UPDATED TITLE",
      AE.DESCRIPTION_O "PREVIOUS DESCRIPTION",
       AE.DESCRIPTION "UPDATED DESCRIPTION",
        AE.CAUSE_O "PREVIOUS CAUSE",
       AE.CAUSE "UPDATED CAUSE",
       AE.ACTION_O "PREVIOUS ACTION",
       AE.ACTION "UPDATED ACTION"
       FROM TB_MERCHANTS M
      JOIN A_APP_ERRORS AE on (coalesce(AE.MERCHANT_id,AE.MERCHANT_id_o) = M.MERCHANT_ID)
      LEFT OUTER JOIN TB_AUTHORITIES A ON (AE.AUTHORITY_ID = A.AUTHORITY_ID)
      LEFT OUTER JOIN TB_AUTHORITIES AO ON (AO.AUTHORITY_ID = AE.AUTHORITY_ID)
      WHERE M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      AND AE.CHANGE_DATE > '''||v_change_date_after||'''
      AND AE.CHANGE_DATE < '''||v_change_date_before||'''
      ORDER BY AE.CHANGE_VERSION, AO.NAME, A.NAME
    ');
    end_worksheet;
    start_worksheet('RATES');
    run_query('SELECT COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) "OPERATION_TYPE", 
      COALESCE(R.CHANGE_VERSION,RT.CHANGE_VERSION) "VERSION", 
      COALESCE(R.CHANGE_DATE,RT.CHANGE_DATE) "CHANGE DATE",
      COALESCE(A.NAME,AE.NAME) "AUTHORITY NAME", 
      R.DESCRIPTION_O "PREVIOUS RATE DESCRIPTION", 
      COALESCE(R.DESCRIPTION,RE.DESCRIPTION) "UPDATED RATE DESCRIPTION", 
      R.RATE_CODE_O "PREVIOUS RATE CODE", 
      COALESCE(R.RATE_CODE,RE.RATE_CODE) "UPDATED RATE CODE", 
      R.RATE_O "PREVIOUS RATE", 
      COALESCE(R.RATE,RE.RATE) "UPDATED RATE", 
      R.FLAT_FEE_O "PREVIOUS FEE", 
      COALESCE(R.FLAT_FEE,RE.FLAT_FEE) "UPDATED FEE", 
      CASE R.SPLIT_TYPE_O 
        WHEN ''R'' THEN ''Tiered'' 
        WHEN ''G'' THEN ''Graduated'' 
        WHEN ''T'' THEN ''Texas City/Cnty Max'' 
        ELSE DECODE(COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE), ''CREATED'', NULL, ''Basic'') 
        END AS "PREVIOUS TIER TYPE", 
      CASE COALESCE(R.SPLIT_TYPE,RE.SPLIT_TYPE)
        WHEN ''R'' THEN ''Tiered'' 
        WHEN ''G'' THEN ''Graduated'' 
        WHEN ''T'' THEN ''Texas City/Cnty Max'' 
        ELSE DECODE(COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE), ''DELETED'', NULL, ''Basic'') 
        END AS "UPDATED TIER TYPE", 
      R.START_DATE_O "PREVIOUS START DATE", 
      COALESCE(R.START_DATE,RE.START_DATE) "UPDATED START DATE", 
      R.END_DATE_O "PREVIOUS END DATE", 
      COALESCE(R.END_DATE,RE.END_DATE) "UPDATED END DATE", 
      R.IS_LOCAL_O "PREVIOUS CASCADING", 
      COALESCE(R.IS_LOCAL,RE.IS_LOCAL) "UPDATED CASCADING",
      R.UNIT_OF_MEASURE_CODE_O "PREVIOUS UNIT OF MEASURE", 
      COALESCE(R.UNIT_OF_MEASURE_CODE,RE.UNIT_OF_MEASURE_CODE) "UPDATED UNIT OF MEASURE",
      CO.NAME "PREVIOUS CURRENCY", 
      C.NAME "UPDATED CURRENCY", 
      CASE R.SPLIT_AMOUNT_TYPE_O 
        WHEN ''P'' THEN ''Invoice Amount By Rule'' 
        WHEN ''L'' THEN ''Line Amount'' 
        WHEN ''I'' THEN ''Invoice Amount'' 
        WHEN ''T'' THEN ''Item Amount'' 
        WHEN ''Q'' THEN ''Quantity'' 
        END AS "PREVIOUS TIER AMOUNT TYPE", 
      CASE COALESCE(R.SPLIT_AMOUNT_TYPE,RE.SPLIT_AMOUNT_TYPE)
        WHEN ''P'' THEN ''Invoice Amount By Rule'' 
        WHEN ''L'' THEN ''Line Amount'' 
        WHEN ''I'' THEN ''Invoice Amount'' 
        WHEN ''T'' THEN ''Item Amount'' 
        WHEN ''Q'' THEN ''Quantity'' 
        END AS "UPDATED TIER AMOUNT TYPE", 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE coalesce(RT.AMOUNT_LOW_O,RTE.AMOUNT_LOW)
        END AS "PREVIOUS AMOUNT LOW", 
      COALESCE(RT.AMOUNT_LOW, RTE.AMOUNT_LOW) "UPDATED AMOUNT LOW", --Prefer audited change over existing value 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RT.AMOUNT_HIGH_O,RTE.AMOUNT_HIGH)
        END AS "PREVIOUS AMOUNT HIGH", 
      coalesce(RT.AMOUNT_HIGH, RTE.AMOUNT_HIGH) "UPDATED AMOUNT HIGH",
      CASE COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE)
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RT.RATE_O, RTE.RATE) 
        END AS "PREVIOUS TIERED RATE",
      coalesce(RT.RATE, RTE.RATE) "UPDATED TIERED RATE", 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RT.RATE_CODE_O, RTE.RATE_CODE)
        END AS "PREVIOUS REFERENCED RATE CODE", 
      COALESCE(RT.RATE_CODE, RTE.RATE_CODE) "UPDATED REFERENCED RATE CODE" 
      FROM A_RATES R 
      JOIN TB_AUTHORITIES A ON (A.AUTHORITY_ID = COALESCE(R.AUTHORITY_ID,R.AUTHORITY_ID_O)) 
      JOIN TB_MERCHANTS M ON (M.MERCHANT_ID = A.MERCHANT_ID) 
      FULL outer JOIN A_RATE_TIERS RT ON (COALESCE(RT.RATE_ID,RT.RATE_ID_O) = COALESCE(R.RATE_ID,R.RATE_ID_O) AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'') --IF CREATED THEN PREFER R AND RTE AND IF IT IS NOT ONLY A RATE CHANGE
      LEFT join TB_RATE_TIERS RTE ON (RTE.RATE_ID = COALESCE(R.RATE_ID,R.RATE_ID_O) AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''-UPDATED'') --IF IT IS ONLY A RATE TIER CHANGE DON''T GO FIND THESE TIERS
      LEFT JOIN TB_RATES RE ON (RE.RATE_ID = COALESCE(RT.RATE_ID,RT.RATE_ID_O) AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'') 
      LEFT JOIN TB_AUTHORITIES AE ON (AE.AUTHORITY_ID = RE.AUTHORITY_ID AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN TB_CURRENCIES C ON (C.CURRENCY_ID = COALESCE(R.CURRENCY_ID,RE.CURRENCY_ID)) 
      LEFT JOIN TB_CURRENCIES CO ON (CO.CURRENCY_ID = R.CURRENCY_ID_O) 
      WHERE COALESCE(R.CHANGE_DATE, RT.CHANGE_DATE) > '''||v_change_date_after||'''
      AND COALESCE(R.CHANGE_DATE, RT.CHANGE_DATE) < '''||v_change_date_before||'''
      AND M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      ORDER BY COALESCE(R.CHANGE_VERSION, RT.CHANGE_VERSION), COALESCE(A.NAME,AE.NAME), COALESCE(R.RATE_CODE,RE.RATE_CODE), COALESCE(R.IS_LOCAL,RE.IS_LOCAL), COALESCE(R.START_DATE,RE.START_DATE)');
      DBMS_OUTPUT.PUT_LINE('RATES COMPLETE');
    end_worksheet;
    start_worksheet('PRODUCTS');
    run_query('SELECT PC.CHANGE_TYPE "OPERATION TYPE",
      PC.CHANGE_VERSION "VERSION",
      PC.CHANGE_DATE "CHANGE DATE",
      PGO.NAME "PREVIOUS PRODUCT GROUP",
      PG.NAME "UPDATED PRODUCT GROUP",
      PC.NAME_O "PREVIOUS PRODUCT",
      PC.NAME "UPDATED PRODUCT",
      PC.PRODCODE_O "PREVIOUS COMMODITY CODE",
      PC.PRODCODE AS "UPDATED COMMODITY CODE",
      PC.DESCRIPTION_O "PREVIOUS DESCRIPTION",
      PC.DESCRIPTION AS "UPDATED DESCRIPTION"
      FROM A_PRODUCT_CATEGORIES PC, TB_PRODUCT_GROUPS PG, TB_PRODUCT_GROUPS PGO, TB_MERCHANTS M
      WHERE PC.CHANGE_DATE > '''||v_change_date_after||'''
      AND PC.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      AND coalesce(PC.MERCHANT_ID,PC.MERCHANT_ID_O) = M.MERCHANT_ID
      AND PG.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID
      AND PGO.PRODUCT_GROUP_ID(+) = PC.PRODUCT_GROUP_ID_O
      ORDER BY PC.CHANGE_VERSION, PG.NAME, PC.PRODCODE');
      DBMS_OUTPUT.PUT_LINE('PRODUCTS COMPLETE');
    end_worksheet;
    start_worksheet('RULES');
    run_query('SELECT COALESCE(RU.CHANGE_TYPE, RQ.CHANGE_TYPE) "OPERATION TYPE",
      COALESCE(RU.CHANGE_VERSION,RQ.CHANGE_VERSION) "VERSION",
      COALESCE(A.NAME,AE.NAME) "AUTHORITY NAME",
      RU.RULE_ORDER_O "PREVIOUS RULE ORDER",
      COALESCE(RU.RULE_ORDER,RUE.RULE_ORDER) "UPDATED RULE ORDER",
      PCO.NAME "PREVIOUS PRODUCT NAME",
      PC.NAME "UPDATED PRODUCT NAME",
      PCO.PRODCODE "PREVIOUS COMMODITY CODE",
      PC.PRODCODE "UPDATED COMMODITY CODE",
      PGO.NAME "PREVIOUS PRODUCT GROUP",
      PG.NAME "UPDATED PRODUCT GROUP",
      RU.INVOICE_DESCRIPTION_O "PREVIOUS INVOICE DESCRIPTION",
      COALESCE(RU.INVOICE_DESCRIPTION,RUE.INVOICE_DESCRIPTION) "UPDATED INVOICE DESCRIPTION",
      RU.CODE_O "PREVIOUS TAX CODE",
      COALESCE(RU.CODE,RUE.CODE) "UPDATED TAX CODE",
      RU.RATE_CODE_O "PREVIOUS RATE CODE",
      COALESCE(RU.RATE_CODE,RUE.RATE_CODE) "UPDATED RATE CODE",
      RU.EXEMPT_O "PREVIOUS EXEMPT",
      COALESCE(RU.EXEMPT,RUE.EXEMPT) "UPDATED EXEMPT",
      CASE RU.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE NVL(RU.NO_TAX_O,''N'') END AS "PREVIOUS NO TAX",
      NVL(COALESCE(RU.NO_TAX,RUE.NO_TAX),''N'') "UPDATED NO TAX",
      RU.BASIS_PERCENT_O "PREVIOUS BASIS PERCENT",
      COALESCE(RU.BASIS_PERCENT,RUE.BASIS_PERCENT) "UPDATED BASIS_PERCENT",
      RU.IS_LOCAL_O "PREVIOUS CASCADING",
      COALESCE(RU.IS_LOCAL,RUE.IS_LOCAL) "UPDATED CASCADING",
      RU.TAX_TYPE_O "PREVIOUS TAX TYPE",
      COALESCE(RU.TAX_TYPE,RUE.TAX_TYPE) "UPDATED TAX TYPE",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''TBI_CALC_METH'' AND CODE = TO_CHAR(RU.CALCULATION_METHOD_O) ) "PREVIOUS CALC METHOD",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''TBI_CALC_METH'' AND CODE = TO_CHAR(COALESCE(RU.CALCULATION_METHOD,RUE.CALCULATION_METHOD)) ) "UPDATED CALC METHOD",
      RU.INPUT_RECOVERY_AMOUNT_O "PREVIOUS INPUT RECOVERY AMT",
      COALESCE(RU.INPUT_RECOVERY_AMOUNT, RUE.INPUT_RECOVERY_AMOUNT) "UPDATED INPUT RECOVERY AMT",
      COALESCE(RU.INPUT_RECOVERY_PERCENT_O,1) "PREVIOUS INPUT RECOVERY PCT",  --ADDED TO ACCOUNT FOR 5.7 NULL = 100%
      COALESCE(RU.INPUT_RECOVERY_PERCENT,RUE.INPUT_RECOVERY_PERCENT,1) "UPDATED INPUT RECOVERY PCT", --ADDED TO ACCOUNT FOR 5.7 NULL = 100%
      RU.START_DATE_O "PREVIOUS START DATE",
      COALESCE(RU.START_DATE,RUE.START_DATE) "UPDATED START DATE",
      RU.END_DATE_O "PREVIOUS END DATE",
      COALESCE(RU.END_DATE,RUE.END_DATE) "UPDATED END DATE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) END AS "PREVIOUS QUALIFIER TYPE",
      COALESCE(RQ.RULE_QUALIFIER_TYPE, RQE.RULE_QUALIFIER_TYPE) "UPDATED QUALIFIER TYPE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.ELEMENT_O,RQE.ELEMENT) END AS "PREVIOUS QUALIFIER ELEMENT",
      COALESCE(RQ.ELEMENT, RQE.ELEMENT) "UPDATED QUALIFIER ELEMENT",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.OPERATOR_O,RQE.OPERATOR) END AS "PREVIOUS QUALIFIER OPERATOR",
      COALESCE(RQ.OPERATOR, RQE.OPERATOR) "UPDATED QUALIFIER OPERATOR",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.VALUE_O,RQE.VALUE) END AS  "PREVIOUS QUALIFIER VALUE",
      COALESCE(RQ.VALUE,RQE.VALUE) "UPDATED QUALIFIER VALUE",
      RL.NAME "REFERENCE_LIST",
      RA.NAME "REFERENCED_AUTHORITY",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.START_DATE_O,RQE.START_DATE) END AS  "PREVIOUS QUALIFIER START DATE",
      COALESCE(RQ.START_DATE,RQE.START_DATE) "UPDATED QUALIFIER START DATE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.END_DATE_O,RQE.END_DATE) END AS  "PREVIOUS QUALIFIER END DATE",
      COALESCE(RQ.END_DATE,RQE.END_DATE) "UPDATED QUALIFIER END DATE"
      FROM A_RULES RU
      JOIN TB_MERCHANTS M ON (coalesce(RU.MERCHANT_ID,RU.MERCHANT_ID_O) = M.MERCHANT_ID)
      JOIN TB_AUTHORITIES A ON (COALESCE(RU.AUTHORITY_ID,RU.AUTHORITY_ID_O) = A.AUTHORITY_ID)
      FULL OUTER JOIN A_RULE_QUALIFIERS RQ ON (COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) = COALESCE(RU.RULE_ID,RU.RULE_ID_O) AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')--PREFER RQE ON CREATED
      LEFT JOIN TB_RULE_QUALIFIERS RQE ON (RQE.RULE_ID = COALESCE(RU.RULE_ID,RU.RULE_ID_O) AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''-UPDATED'')
      LEFT JOIN TB_RULES RUE ON (RUE.RULE_ID = COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN TB_AUTHORITIES AE ON (RUE.AUTHORITY_ID = AE.AUTHORITY_ID AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN TB_PRODUCT_CATEGORIES PC ON (PC.PRODUCT_CATEGORY_ID = COALESCE(RU.PRODUCT_CATEGORY_ID,RUE.PRODUCT_CATEGORY_ID))
      LEFT JOIN TB_PRODUCT_GROUPS PG ON (PG.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID)
      LEFT JOIN TB_PRODUCT_CATEGORIES PCO ON (PCO.PRODUCT_CATEGORY_ID = RU.PRODUCT_CATEGORY_ID_O)
      LEFT JOIN TB_PRODUCT_GROUPS PGO ON (PGO.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID)
      LEFT JOIN TB_REFERENCE_LISTS RL ON (RL.REFERENCE_LIST_ID = CASE WHEN COALESCE(RQ.RULE_QUALIFIER_TYPE, RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) = ''LIST'' THEN COALESCE(RQ.REFERENCE_LIST_ID, RQ.REFERENCE_LIST_ID_O, RQE.REFERENCE_LIST_ID) ELSE NULL END)
      LEFT JOIN TB_AUTHORITIES RA ON (RL.REFERENCE_LIST_ID = CASE WHEN COALESCE(RQ.RULE_QUALIFIER_TYPE, RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) = ''AUTHORITY'' THEN COALESCE(RQ.AUTHORITY_ID, RQ.AUTHORITY_ID_O, RQE.AUTHORITY_ID) ELSE NULL END)
      WHERE COALESCE(RU.CHANGE_DATE,RQ.CHANGE_DATE) > '''||v_change_date_after||'''
      AND COALESCE(RU.CHANGE_DATE,RQ.CHANGE_DATE) < '''||v_change_date_before||'''
      AND M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      ORDER BY COALESCE(RU.CHANGE_VERSION,RQ.CHANGE_VERSION), COALESCE(A.NAME, AE.NAME), COALESCE(PC.PRODCODE,PCO.PRODCODE), COALESCE(RU.RULE_ORDER,RUE.RULE_ORDER), COALESCE(RU.START_DATE,RUE.START_DATE)');
      DBMS_OUTPUT.PUT_LINE('RULES COMPLETE');
    end_worksheet;
    start_worksheet('AUTHORITY MAPPINGS');
    run_query('SELECT ZA.CHANGE_TYPE "OPERATION TYPE",
      ZA.CHANGE_VERSION "VERSION",
      ZA.CHANGE_DATE "CHANGE DATE",
      ZP2.NAME "GREAT GRAND PARENT ZONE NAME",
      ZP1.NAME "GRAND PARENT ZONE NAME",
      ZP.NAME "PARENT ZONE NAME",
      NVL(ZL.NAME,ZLO.NAME) "ZONE LEVEL",
      --ZO.NAME "OLD ZONE NAME",
      NVL(Z.NAME,ZO.NAME) "ZONE NAME",
      --AO.NAME "OLD AUTHORITY MAPPED",
      A.NAME "AUTHORITY",
      case when za.authority_id is null then ''Detached'' when za.authority_id_o is null then ''Attached'' end "OPERATION"
      FROM TB_MERCHANTS M
      JOIN TB_AUTHORITIES A on (a.merchant_id = m.merchant_id)
      --JOIN TB_AUTHORITIES AO on (ao.merchant_id = m.merchant_id) 
      JOIN A_ZONE_AUTHORITIES ZA on (coalesce(za.authority_id,za.authority_id_o) = a.authority_id)
      LEFT OUTER JOIN TB_ZONES Z on (nvl(ZA.ZONE_ID,0) = Z.ZONE_ID) 
      LEFT OUTER JOIN TB_ZONE_LEVELS ZL on (ZL.ZONE_LEVEL_ID = COALESCE(Z.ZONE_LEVEL_ID, 0))
      LEFT OUTER JOIN TB_ZONES ZO on (nvl(ZA.ZONE_ID_O,0) = ZO.ZONE_ID)
      LEFT OUTER JOIN TB_ZONE_LEVELS ZLO on (ZLO.ZONE_LEVEL_ID = COALESCE(ZO.ZONE_LEVEL_ID, 0))
      LEFT OUTER JOIN TB_ZONES ZP on (ZP.ZONE_ID = COALESCE(Z.PARENT_ZONE_ID, ZO.PARENT_ZONE_ID))
      LEFT OUTER JOIN TB_ZONES ZP1 on (NVL(ZP.PARENT_ZONE_ID, 0) = ZP1.ZONE_ID)
      LEFT OUTER JOIN TB_ZONES ZP2 on (NVL(ZP1.PARENT_ZONE_ID, 0) = ZP2.ZONE_ID)
      WHERE M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      AND ZA.CHANGE_DATE > '''||v_change_date_after||'''
      AND ZA.CHANGE_DATE < '''||v_change_date_before||'''
      order by ZA.CHANGE_VERSION, z.name, a.name');
      DBMS_OUTPUT.PUT_LINE('AUTHORITY MAPPINGS COMPLETE');
    end_worksheet;
    
    start_worksheet('ZONES');
    run_query('SELECT Z.CHANGE_TYPE "OPERATION TYPE",
      Z.CHANGE_VERSION "VERSION",
      Z.CHANGE_DATE "CHANGE DATE",
      ZP2.NAME "GREAT GRANDPARENT",
      ZP1.NAME "GRANDPARENT",
      ZP.NAME "PARENT",
      Z.NAME_O "PREVIOUS NAME",
      Z.NAME "UPDATED NAME",
      ZLO.NAME "PREVIOUS LEVEL",
      ZL.NAME "UPDATED LEVEL",
      Z.EU_ZONE_AS_OF_DATE_O "PREVIOUS EU ZONE AS OF",
      Z.EU_ZONE_AS_OF_DATE "UPDATED EU ZONE AS OF",
      Z.CODE_2CHAR_O "PREVIOUS SHORT CODE",
      Z.CODE_2CHAR "UPDATED SHORT CODE",
      Z.CODE_3CHAR_O "PREVIOUS 3-CHAR CODE",
      Z.CODE_3CHAR "UPDATED 3-CHAR CODE",
      Z.CODE_ISO_O "PREVIOUS ISO CODE",
      Z.CODE_ISO "UPDATED ISO CODE",
      Z.CODE_FIPS_O "PREVIOUS FIPS CODE",
      Z.CODE_FIPS "UPDATED FIPS CODE",
      Z.REVERSE_FLAG_O "PREVIOUS BOTTOM UP PROCESSING",
      Z.REVERSE_FLAG "UPDATED BOTTOM UP PROCESSING",
      Z.TERMINATOR_FLAG_O "PREVIOUS TERMINATES PROCESSING",
      Z.TERMINATOR_FLAG "UPDATED TERMINATES PROCESSING",
	  Z.GCC_AS_OF_DATE_O "PREVIOUS GCC ZONE AS OF",
      Z.GCC_AS_OF_DATE "UPDATED GCC ZONE AS OF",
      Z.EU_EXIT_DATE_O "PREVIOUS EU EXIT DATE",
      Z.EU_EXIT_DATE "UPDATED EU EXIT DATE",
      Z.GCC_EXIT_DATE_O "PREVIOUS GCC EXIT DATE",
      Z.GCC_EXIT_DATE "UPDATED GCC EXIT DATE",
      Z.DEFAULT_FLAG_O "PREVIOUS DEFAULT",
      Z.DEFAULT_FLAG "UPDATED DEFAULT"
      FROM A_ZONES Z
      LEFT OUTER JOIN TB_ZONES ZP ON (COALESCE(Z.PARENT_ZONE_ID,Z.PARENT_ZONE_ID_O) = ZP.ZONE_ID)
      LEFT OUTER JOIN TB_ZONE_LEVELS ZL ON ( Z.ZONE_LEVEL_ID = ZL.ZONE_LEVEL_ID)
      JOIN TB_MERCHANTS M ON (M.MERCHANT_ID = coalesce(Z.MERCHANT_ID,Z.MERCHANT_ID_O))
      LEFT OUTER JOIN TB_ZONE_LEVELS ZLO ON(ZLO.ZONE_LEVEL_ID = Z.ZONE_LEVEL_ID_O)
      LEFT OUTER JOIN TB_ZONES ZP1 ON (ZP1.ZONE_ID = ZP.PARENT_ZONE_ID )
      LEFT OUTER JOIN TB_ZONES ZP2 ON (ZP2.ZONE_ID = ZP1.PARENT_ZONE_ID )
      WHERE Z.CHANGE_DATE > '''||v_change_date_after||'''
      AND Z.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      --AND COALESCE(Z.ZONE_LEVEL_ID,Z.ZONE_LEVEL_ID_O) > -7
      ORDER BY Z.CHANGE_VERSION, ZP2.NAME, ZP1.NAME, ZP.NAME, Z.NAME');
      DBMS_OUTPUT.PUT_LINE('ZONES COMPLETE');
    end_worksheet;
 
       start_worksheet('ZONE ALIAS');
    run_query('SELECT COALESCE(ZMC.CHANGE_TYPE,ZMP.CHANGE_TYPE) "OPERATION TYPE",
      COALESCE(ZMC.CHANGE_VERSION, ZMP.CHANGE_VERSION) "VERSION",
      ZMP.PATTERN_O "PREVIOUS PATTERN",
      COALESCE(ZMP.PATTERN,ZMPE.PATTERN) "UPDATED PATTERN",
      ZMP.VALUE_O "PREVIOUS VALUE",
      COALESCE(ZMP.VALUE,ZMPE.VALUE) "UPDATED VALUE",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''ZONE_ALIAS_TYPE'' AND CODE = ZMP.TYPE_O) "PREVIOUS TYPE",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''ZONE_ALIAS_TYPE'' AND CODE = COALESCE(ZMP.TYPE,ZMPE.TYPE)) "UPDATED TYPE",
      case COALESCE(ZMC.CHANGE_TYPE,ZMP.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE (SELECT ZONE_ID FROM TB_ZONES WHERE ZONE_ID = COALESCE(ZMC.ZONE_ID_O, ZMCE.ZONE_ID))
        END AS "PREVIOUS ZONE", 
      (SELECT ZONE_ID FROM TB_ZONES WHERE ZONE_ID = COALESCE(ZMC.ZONE_ID, ZMCE.ZONE_ID)) "UPDATED ZONE" ,
      case COALESCE(ZMC.CHANGE_TYPE,ZMP.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE (SELECT NAME FROM TB_ZONE_LEVELS WHERE ZONE_LEVEL_ID = COALESCE(ZMC.ZONE_LEVEL_ID_O, ZMCE.ZONE_LEVEL_ID))
        END AS "PREVIOUS ZONE LEVEL", 
      (SELECT NAME FROM TB_ZONE_LEVELS WHERE ZONE_LEVEL_ID = COALESCE(ZMC.ZONE_LEVEL_ID, ZMCE.ZONE_LEVEL_ID)) "UPDATED ZONE LEVEL"      
      FROM a_ZONE_MATCH_PATTERNS ZMP
      FULL JOIN A_ZONE_MATCH_CONTEXTS ZMC on (COALESCE(ZMP.ZONE_MATCH_PATTERN_ID, ZMP.ZONE_MATCH_PATTERN_ID_O) = COALESCE(ZMC.ZONE_MATCH_PATTERN_ID,ZMC.ZONE_MATCH_PATTERN_ID_O) AND ZMC.CHANGE_TYPE != ''CREATED'' AND (ZMP.CHANGE_TYPE||''-''||ZMC.CHANGE_TYPE)!=''UPDATED-'')
      LEFT join TB_ZONE_MATCH_CONTEXTS ZMCE ON (ZMCE.ZONE_MATCH_PATTERN_ID = COALESCE(ZMP.ZONE_MATCH_PATTERN_ID,ZMP.ZONE_MATCH_PATTERN_ID_O) AND (ZMP.CHANGE_TYPE||''-''||ZMC.CHANGE_TYPE)!=''-UPDATED'')
      LEFT JOIN TB_ZONE_MATCH_PATTERNS ZMPE ON (ZMPE.ZONE_MATCH_PATTERN_ID = COALESCE(ZMC.ZONE_MATCH_PATTERN_ID,ZMC.ZONE_MATCH_PATTERN_ID_O) AND ZMC.CHANGE_TYPE != ''CREATED'' AND (ZMP.CHANGE_TYPE||''-''||ZMC.CHANGE_TYPE)!=''UPDATED-'') 
      JOIN TB_MERCHANTS M ON (M.MERCHANT_ID = COALESCE(ZMP.MERCHANT_ID, ZMP.MERCHANT_ID_O, ZMPE.MERCHANT_ID))
      WHERE M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      AND COALESCE(ZMC.CHANGE_DATE, ZMP.CHANGE_DATE) > '''||v_change_date_after||'''
      AND COALESCE(ZMC.CHANGE_DATE, ZMP.CHANGE_DATE) < '''||v_change_date_before||'''
      ORDER BY COALESCE(ZMC.CHANGE_DATE,ZMP.CHANGE_DATE), COALESCE(ZMP.PATTERN_O, ZMP.PATTERN,ZMPE.PATTERN), COALESCE(ZMP.VALUE_O, ZMP.VALUE,ZMPE.VALUE) ');
      --DBMS_OUTPUT.PUT_LINE('ZONE ALIAS COMPLETE');
    end_worksheet;   
    
      start_worksheet('REFERENCE LISTS');
    run_query('SELECT COALESCE(RV.CHANGE_TYPE,RL.CHANGE_TYPE) "OPERATION TYPE",
      COALESCE(RV.CHANGE_VERSION, RL.CHANGE_VERSION) "VERSION",
      RL.NAME_O "PREVIOUS REF LIST NAME",
      COALESCE(RL.NAME,RLE.NAME) "UPDATED REF LIST NAME",
      RL.DESCRIPTION_O "PREVIOUS REF LIST DESCRIPTION",
      COALESCE(RL.DESCRIPTION,RLE.DESCRIPTION) "UPDATED REF LIST DESCRIPTION",
      RL.START_DATE_O "PREVIOUS REF LIST START DATE",
      COALESCE(RL.START_DATE,RLE.START_DATE) "UPDATED REF LIST START DATE",
      RL.END_DATE_O "PREVIOUS REF LIST END DATE",
      COALESCE(RL.END_DATE,RLE.END_DATE) "UPDATED REF LIST END DATE",
      case COALESCE(RV.CHANGE_TYPE,RL.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RV.VALUE_O, RVE.VALUE)
        END AS "PREVIOUS REF VALUE", 
      COALESCE(RV.VALUE, RVE.VALUE) "UPDATED REF VALUE" ,
      case COALESCE(RV.CHANGE_TYPE,RL.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RV.START_DATE_O, RVE.START_DATE)
        END AS "PREVIOUS REF START DATE", 
      COALESCE(RV.START_DATE, RVE.START_DATE) "UPDATED REF START DATE",      
      case COALESCE(RV.CHANGE_TYPE,RL.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RV.END_DATE_O, RVE.END_DATE)
        END AS "PREVIOUS REF END DATE", 
      COALESCE(RV.END_DATE, RVE.END_DATE) "UPDATED REF END DATE" 
      FROM a_reference_lists RL
      FULL JOIN A_REFERENCE_VALUES RV on (COALESCE(RL.REFERENCE_LIST_ID, RL.REFERENCE_LIST_ID_O) = COALESCE(RV.REFERENCE_LIST_ID,RV.REFERENCE_LIST_ID_O) AND RV.CHANGE_TYPE != ''CREATED'' AND (RL.CHANGE_TYPE||''-''||RV.CHANGE_TYPE)!=''UPDATED-'')
      LEFT join TB_REFERENCE_VALUES RVE ON (RVE.REFERENCE_LIST_ID = COALESCE(RL.REFERENCE_LIST_ID,RL.REFERENCE_LIST_ID_O) AND (RL.CHANGE_TYPE||''-''||RV.CHANGE_TYPE)!=''-UPDATED'') 
      LEFT JOIN TB_REFERENCE_LISTS RLE ON (RLE.REFERENCE_LIST_ID = COALESCE(RV.REFERENCE_LIST_ID,RV.REFERENCE_LIST_ID_O) AND RV.CHANGE_TYPE != ''CREATED'' AND (RL.CHANGE_TYPE||''-''||RV.CHANGE_TYPE)!=''UPDATED-'') 
      JOIN TB_MERCHANTS M ON (M.MERCHANT_ID = COALESCE(RL.MERCHANT_ID, RL.MERCHANT_ID_O, RLE.MERCHANT_ID))
      WHERE M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      AND COALESCE(RV.CHANGE_DATE, RL.CHANGE_DATE) > '''||v_change_date_after||'''
      AND COALESCE(RV.CHANGE_DATE, RL.CHANGE_DATE) < '''||v_change_date_before||'''
      ORDER BY COALESCE(RV.CHANGE_DATE,RL.CHANGE_DATE), COALESCE(RL.NAME_O, RL.NAME,RLE.NAME), COALESCE(RV.VALUE_O, RV.VALUE,RVE.VALUE)'
    );
    end_worksheet;
    end_workbook;
    if length(io_buffer)>0 then
          DBMS_LOB.writeappend(v_clob, LENGTH(io_buffer), io_buffer);
    end if;
  END create_full_change_clob;

  PROCEDURE create_simple_rates_file( v_content_type IN OUT VARCHAR2, v_content_version IN OUT VARCHAR2, v_change_date_after IN OUT DATE, v_change_date_before IN OUT DATE)
  AS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('Creating Simple Rates file for checkpoint');
    start_workbook;
    set_date_style;
    start_worksheet('RATES');
    run_query('SELECT
      R.CHANGE_TYPE,
      A.NAME "AUTHORITY NAME",
      R.DESCRIPTION "RATE DESCRIPTION",
      R.RATE_CODE "RATE CODE",
      R.RATE "RATE",
      R.FLAT_FEE "FEE",
      R.SPLIT_TYPE "TIER TYPE",
      R.SPLIT_AMOUNT_TYPE "TIER AMOUNT TYPE",
      RT.AMOUNT_LOW "AMOUNT LOW",
      RT.AMOUNT_HIGH "AMOUNT HIGH",
      coalesce(R2.RATE, rt.rate) "TIERED RATE",
      RT.RATE_CODE "REFERENCED RATE CODE",
      R.UNIT_OF_MEASURE_CODE "UNIT OF MEASURE",
      R.START_DATE "START DATE",
      R.END_DATE "END DATE"
      FROM A_RATES R
      JOIN TB_AUTHORITIES A ON (A.AUTHORITY_ID = COALESCE(R.AUTHORITY_ID,R.AUTHORITY_ID_O))
      JOIN TB_MERCHANTS M ON (M.MERCHANT_ID = A.MERCHANT_ID)
      full OUTER JOIN TB_RATE_TIERS RT ON (RT.RATE_ID = COALESCE(R.RATE_ID,R.RATE_ID_O))
      left outer JOIN TB_RATES R2 ON (nvl(RT.RATE_CODE,''XXX'') = NVL(R2.RATE_CODE,''XXX'') AND A.AUTHORITY_ID = R2.AUTHORITY_ID AND COALESCE(R.START_DATE,R.START_DATE_O) > R2.START_DATE AND NVL(R2.END_DATE, ''31-DEC-2099'') > NVL(COALESCE(R.END_DATE,R.END_DATE_O), ''31-DEC-2098'') and COALESCE(r.rate,R.RATE_O) is null)
      WHERE R.CHANGE_DATE > '''||v_change_date_after||'''
      AND R.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.NAME = ''Sabrix ''||'''||v_content_type||'''||'' Tax Data''
      ORDER BY A.NAME, R.RATE_CODE, R.START_DATE');
    end_worksheet;
    end_workbook;
    if length(io_buffer)>0 then
        DBMS_OUTPUT.put_line('buffer:'||io_buffer);
          DBMS_LOB.writeappend(v_clob, LENGTH(io_buffer), io_buffer);
    end if;
  END create_simple_rates_file;

END CHANGE_RECORD_DATE;
/