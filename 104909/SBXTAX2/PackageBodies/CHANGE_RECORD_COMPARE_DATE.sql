CREATE OR REPLACE PACKAGE BODY sbxtax2."CHANGE_RECORD_COMPARE_DATE" 
AS
    v_clob CLOB;
    v_chunked_clob CLOB;
    io_buffer VARCHAR2(32767 CHAR) := ' ';
	-- removed CHANGE_VERSION column from all the select statements of both MINUS/UNION queries as part of CRAPP-4255
    
PROCEDURE Generate_change_record(
      schema1_name IN VARCHAR2,
      system1_name IN VARCHAR2,
      schema2_name IN VARCHAR2,
      system2_name IN VARCHAR2,
      content_type    IN VARCHAR2,
      content_consumer IN VARCHAR2,
      content_description IN VARCHAR2,
      oracle_directory IN VARCHAR2,
      overwrite_existing IN NUMBER,
      change_date_after IN DATE,
      change_date_before IN DATE,
      change_date_after2 IN DATE,
      change_date_before2 IN DATE,
      id_o OUT NUMBER,
      success_o OUT NUMBER)
  as
    v_schema1_name VARCHAR2(20 BYTE) := schema1_name;
    v_system1_name VARCHAR2(20 BYTE) := system1_name;
    v_schema2_name VARCHAR2(20 BYTE) := schema2_name;
    v_system2_name VARCHAR2(20 BYTE) := system2_name;
    v_change_date_after DATE := change_date_after;
    v_change_date_after2 DATE := change_date_after2;
    v_content_type    VARCHAR2(100 BYTE) := content_type;    --example: 'INTL' or 'US'
    v_content_version VARCHAR2(500 BYTE)  := v_system1_name||'('||to_char(change_date_after, 'DD-MON-YYYY')||'to'||nvl(to_char(change_date_before, 'DD-MON-YYYY'),'EOT')||')-ComparedTo-'||v_system2_name||'('||to_char(change_date_after2, 'DD-MON-YYYY')||'to'||nvl(to_char(change_date_before2, 'DD-MON-YYYY'),'EOT')||')'; --Start date is required
    v_content_consumer VARCHAR2(100 BYTE) := content_consumer; --Who is the content being sent to
    v_content_description VARCHAR2(500 BYTE) := content_description;  --Describe the content
    v_oracle_directory VARCHAR2(50 BYTE) := oracle_directory; --NULL if writing to DB only, if populated will generate XLS file to oracle directory
    v_overwrite_existing NUMBER := overwrite_existing; --A 1 will re-create the CLOB if it already exists
    
    v_change_date_before DATE := nvl(change_date_before,'31-dec-2032');--default to a long time from now
    v_change_date_before2 DATE := nvl(change_date_before2,'31-dec-2032');--default to a long time from now

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
      and content_description = v_content_description
      and content_version = v_content_version; --look for the date range in the content_version
      --AND nvl(v_include_multiple_updates,1) < 2;--If user gave a number of updates, then we should not find anything here (will create a duplicate but oh well
      DBMS_OUTPUT.PUT_LINE('Existing record found for requested version, A_CHANGE_RECORD.id: '||v_id);
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('No existing record found for requested version.');
      v_id := NULL;
    END;

        
    IF v_id IS NULL OR (v_overwrite_existing = 1 AND v_id IS NOT NULL) THEN --It doesn't exist or the user wants to overwrite the existing
        DBMS_OUTPUT.PUT_LINE('Content consumer: '||v_content_consumer);
        DBMS_OUTPUT.PUT_LINE('Creating Comparison for:'||v_content_version);
        create_full_change_clob(v_content_type, v_content_version, v_change_date_after, v_change_date_before, v_schema1_name, v_system1_name, v_schema2_name, v_system2_name, v_change_date_after2, v_change_date_before2);

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
    --DBMS_OUTPUT.PUT_LINE('sql ran:'||p_sql);
    DBMS_SQL.PARSE(c, p_sql, DBMS_SQL.NATIVE);
    -- start execution of the SQL statement
    d := DBMS_SQL.EXECUTE(c);
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
      append_text(v_clob,io_buffer, '<Cell>');
      append_text(v_clob,io_buffer, '<Data ss:Type="String">'||rec_tab(j).col_name||'</Data>');
      append_text(v_clob,io_buffer, '</Cell>');
    END LOOP;
    append_text(v_clob,io_buffer, '</Row>');
    -- Output the data
    LOOP
      v_ret := DBMS_SQL.FETCH_ROWS(c);
      EXIT WHEN v_ret = 0;
      append_text(v_clob,io_buffer, '<Row>');
      FOR j in 1..col_cnt
      LOOP
        CASE rec_tab(j).col_type
          WHEN 1 THEN DBMS_SQL.COLUMN_VALUE(c,j,v_v_val);
                      IF (j>1 AND 'OLD '||rec_tab(j).col_name = rec_tab(j-1).col_name AND rec_tab(j).col_name != 'VERSION') THEN
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
                        IF (j>1 AND 'OLD '||rec_tab(j).col_name = rec_tab(j-1).col_name) THEN
                          DBMS_SQL.COLUMN_VALUE(c,(j-1),v_n_val_o);--GET PRIOR COLUMN VALUE
                          DBMS_SQL.COLUMN_VALUE(c, 1, v_change_type);--GET CHANGE TYPE
                          IF (NVL(v_n_val_o,9999999999) != NVL(v_n_val,9999999999) AND v_change_type = 'UPDATED') THEN --IF THEY ARE DIFFERENT
                            --Special case for FEE
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
                       IF (j>1 AND 'OLD '||rec_tab(j).col_name = rec_tab(j-1).col_name) THEN
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
      ');
    END LOOP;
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
 ');
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
    DBMS_OUTPUT.PUT_LINE('Starting Worksheet:'||p_sheetname||' at:'||SYSTIMESTAMP);
    append_text(v_clob,io_buffer, '<Worksheet ss:Name="'||p_sheetname||'">');
    append_text(v_clob,io_buffer, '<Table>');
  END start_worksheet;
  PROCEDURE end_worksheet
  AS
  BEGIN
   DBMS_OUTPUT.PUT_LINE('Ending Worksheet: at:'||SYSTIMESTAMP);
    append_text(v_clob,io_buffer, '</Table>');
    append_text(v_clob,io_buffer, '</Worksheet>
    ');
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
    ');
  END set_date_style;

  PROCEDURE create_full_change_clob(v_content_type IN OUT VARCHAR2, v_content_version IN OUT VARCHAR2, v_change_date_after IN OUT DATE, v_change_date_before IN OUT DATE, v_schema1_name IN OUT VARCHAR2, v_system1_name IN OUT VARCHAR2, v_schema2_name IN OUT VARCHAR2, v_system2_name IN OUT VARCHAR2, v_change_date_after2 IN OUT DATE, v_change_date_before2 IN OUT DATE )
  AS
  BEGIN
    start_workbook;
    set_date_style;
    start_worksheet('AUTHORITIES');
    run_query('
    (
    select ''Change Only in '||v_system1_name||''' "CHANGE LOCATION", a.change_type "OPERATION TYPE",      A.NAME_O "OLD NAME",      a.NAME "NAME",     
      A.OFFICIAL_NAME_O "OLD OFFICIAL NAME",      A.OFFICIAL_NAME "OFFICIAL NAME",      A.AUTHORITY_CATEGORY_O "OLD AUTHORITY CATEGORY",      A.AUTHORITY_CATEGORY "AUTHORITY CATEGORY",      A.INVOICE_DESCRIPTION_O "OLD INVOICE DESCRIPTION",
      A.INVOICE_DESCRIPTION "INVOICE DESCRIPTION",      A.REGION_CODE_O "OLD AUTHORITY FIPS",      A.REGION_CODE "AUTHORITY FIPS",      A.DESCRIPTION_O "OLD DESCRIPTION",      A.DESCRIPTION "DESCRIPTION",
      ATO.NAME "OLD AUTHORITY TYPE",      AT.NAME "AUTHORITY TYPE",      A.REGISTRATION_MASK_O "OLD REGISTRATION MASK",      a.REGISTRATION_MASK "REGISTRATION MASK",      A.SIMPLE_REGISTRATION_MASK_O "OLD SIMPLE REG MASK",
      a.SIMPLE_REGISTRATION_MASK "SIMPLE REG MASK",      A.LOCATION_CODE_O "OLD LOCATION CODE",      a.LOCATION_CODE "LOCATION CODE",      A.DISTANCE_SALES_THRESHOLD_O "OLD DISTANCE THRESHOLD",      A.DISTANCE_SALES_THRESHOLD "DISTANCE THRESHOLD",
      A.CONTENT_TYPE_O "OLD CONTENT TYPE",      A.CONTENT_TYPE "CONTENT TYPE",      PGO.NAME "OLD PRODUCT GROUP",      PG.NAME "PRODUCT GROUP",      ZLO.NAME "OLD ADMIN LEVEL",
      ZL.NAME "ADMIN LEVEL",      ZEO.NAME "OLD EFFECTIVE LEVEL",      ZE.NAME "EFFECTIVE LEVEL"
      from '||v_schema1_name||'.A_authorities A, '||v_schema1_name||'.TB_ZONE_LEVELS ZL, '||v_schema1_name||'.TB_ZONE_LEVELS ZE, '||v_schema1_name||'.TB_AUTHORITY_TYPES AT, '||v_schema1_name||'.TB_ZONE_LEVELS ZLO,
      '||v_schema1_name||'.TB_ZONE_LEVELS ZEO, '||v_schema1_name||'.TB_AUTHORITY_TYPES ATO, '||v_schema1_name||'.TB_MERCHANTS M, '||v_schema1_name||'.TB_PRODUCT_GROUPS PG, '||v_schema1_name||'.TB_PRODUCT_GROUPS PGO
      WHERE A.CHANGE_DATE > '''||v_change_date_after||'''
      AND A.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.MERCHANT_ID = COALESCE(A.MERCHANT_ID,A.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND A.ADMIN_ZONE_LEVEL_ID = ZL.ZONE_LEVEL_ID(+)
      AND A.EFFECTIVE_ZONE_LEVEL_ID = ZE.ZONE_LEVEL_ID(+)
      AND A.AUTHORITY_TYPE_ID = AT.AUTHORITY_TYPE_ID(+)
      AND A.AUTHORITY_TYPE_ID_O = ATO.AUTHORITY_TYPE_ID(+)
      AND A.EFFECTIVE_ZONE_LEVEL_ID_O = ZEO.ZONE_LEVEL_ID(+)
      AND A.ADMIN_ZONE_LEVEL_ID_O = ZLO.ZONE_LEVEL_ID(+)
      AND A.PRODUCT_GROUP_ID = PG.PRODUCT_GROUP_ID(+)
      AND A.PRODUCT_GROUP_ID_O = PGO.PRODUCT_GROUP_ID(+)
      minus
     select ''Change Only in '||v_system1_name||''' "CHANGE LOCATION", a.change_type "OPERATION TYPE",      A.NAME_O "OLD NAME",      a.NAME "NAME",     
      A.OFFICIAL_NAME_O "OLD OFFICIAL NAME",      A.OFFICIAL_NAME "OFFICIAL NAME",      A.AUTHORITY_CATEGORY_O "OLD AUTHORITY CATEGORY",      A.AUTHORITY_CATEGORY "AUTHORITY CATEGORY",      A.INVOICE_DESCRIPTION_O "OLD INVOICE DESCRIPTION",
      A.INVOICE_DESCRIPTION "INVOICE DESCRIPTION",      A.REGION_CODE_O "OLD AUTHORITY FIPS",      A.REGION_CODE "AUTHORITY FIPS",      A.DESCRIPTION_O "OLD DESCRIPTION",      A.DESCRIPTION "DESCRIPTION",
      ATO.NAME "OLD AUTHORITY TYPE",      AT.NAME "AUTHORITY TYPE",      A.REGISTRATION_MASK_O "OLD REGISTRATION MASK",      a.REGISTRATION_MASK "REGISTRATION MASK",      A.SIMPLE_REGISTRATION_MASK_O "OLD SIMPLE REG MASK",
      a.SIMPLE_REGISTRATION_MASK "SIMPLE REG MASK",      A.LOCATION_CODE_O "OLD LOCATION CODE",      a.LOCATION_CODE "LOCATION CODE",      A.DISTANCE_SALES_THRESHOLD_O "OLD DISTANCE THRESHOLD",      A.DISTANCE_SALES_THRESHOLD "DISTANCE THRESHOLD",
      A.CONTENT_TYPE_O "OLD CONTENT TYPE",      A.CONTENT_TYPE "CONTENT TYPE",      PGO.NAME "OLD PRODUCT GROUP",      PG.NAME "PRODUCT GROUP",      ZLO.NAME "OLD ADMIN LEVEL",
      ZL.NAME "ADMIN LEVEL",      ZEO.NAME "OLD EFFECTIVE LEVEL",      ZE.NAME "EFFECTIVE LEVEL"
      from '||v_schema2_name||'.A_authorities A, '||v_schema2_name||'.TB_ZONE_LEVELS ZL, '||v_schema2_name||'.TB_ZONE_LEVELS ZE, '||v_schema2_name||'.TB_AUTHORITY_TYPES AT, '||v_schema2_name||'.TB_ZONE_LEVELS ZLO,
      '||v_schema2_name||'.TB_ZONE_LEVELS ZEO, '||v_schema2_name||'.TB_AUTHORITY_TYPES ATO, '||v_schema2_name||'.TB_MERCHANTS M, '||v_schema2_name||'.TB_PRODUCT_GROUPS PG, '||v_schema2_name||'.TB_PRODUCT_GROUPS PGO
      WHERE A.CHANGE_DATE > '''||v_change_date_after2||'''
      AND A.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.MERCHANT_ID = COALESCE(A.MERCHANT_ID,A.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND A.ADMIN_ZONE_LEVEL_ID = ZL.ZONE_LEVEL_ID(+)
      AND A.EFFECTIVE_ZONE_LEVEL_ID = ZE.ZONE_LEVEL_ID(+)
      AND A.AUTHORITY_TYPE_ID = AT.AUTHORITY_TYPE_ID(+)
      AND A.AUTHORITY_TYPE_ID_O = ATO.AUTHORITY_TYPE_ID(+)
      AND A.EFFECTIVE_ZONE_LEVEL_ID_O = ZEO.ZONE_LEVEL_ID(+)
      AND A.ADMIN_ZONE_LEVEL_ID_O = ZLO.ZONE_LEVEL_ID(+)
      AND A.PRODUCT_GROUP_ID = PG.PRODUCT_GROUP_ID(+)
      AND A.PRODUCT_GROUP_ID_O = PGO.PRODUCT_GROUP_ID(+)
      )
      UNION ALL
      (
     select ''Change Only in '||v_system2_name||''' "CHANGE LOCATION", a.change_type "OPERATION TYPE",      A.NAME_O "OLD NAME",      a.NAME "NAME",     
      A.OFFICIAL_NAME_O "OLD OFFICIAL NAME",      A.OFFICIAL_NAME "OFFICIAL NAME",      A.AUTHORITY_CATEGORY_O "OLD AUTHORITY CATEGORY",      A.AUTHORITY_CATEGORY "AUTHORITY CATEGORY",      A.INVOICE_DESCRIPTION_O "OLD INVOICE DESCRIPTION",
      A.INVOICE_DESCRIPTION "INVOICE DESCRIPTION",      A.REGION_CODE_O "OLD AUTHORITY FIPS",      A.REGION_CODE "AUTHORITY FIPS",      A.DESCRIPTION_O "OLD DESCRIPTION",      A.DESCRIPTION "DESCRIPTION",
      ATO.NAME "OLD AUTHORITY TYPE",      AT.NAME "AUTHORITY TYPE",      A.REGISTRATION_MASK_O "OLD REGISTRATION MASK",      a.REGISTRATION_MASK "REGISTRATION MASK",      A.SIMPLE_REGISTRATION_MASK_O "OLD SIMPLE REG MASK",
      a.SIMPLE_REGISTRATION_MASK "SIMPLE REG MASK",      A.LOCATION_CODE_O "OLD LOCATION CODE",      a.LOCATION_CODE "LOCATION CODE",      A.DISTANCE_SALES_THRESHOLD_O "OLD DISTANCE THRESHOLD",      A.DISTANCE_SALES_THRESHOLD "DISTANCE THRESHOLD",
      A.CONTENT_TYPE_O "OLD CONTENT TYPE",      A.CONTENT_TYPE "CONTENT TYPE",      PGO.NAME "OLD PRODUCT GROUP",      PG.NAME "PRODUCT GROUP",      ZLO.NAME "OLD ADMIN LEVEL",
      ZL.NAME "ADMIN LEVEL",      ZEO.NAME "OLD EFFECTIVE LEVEL",      ZE.NAME "EFFECTIVE LEVEL"
      from '||v_schema2_name||'.A_authorities A, '||v_schema2_name||'.TB_ZONE_LEVELS ZL, '||v_schema2_name||'.TB_ZONE_LEVELS ZE, '||v_schema2_name||'.TB_AUTHORITY_TYPES AT, '||v_schema2_name||'.TB_ZONE_LEVELS ZLO,
      '||v_schema2_name||'.TB_ZONE_LEVELS ZEO, '||v_schema2_name||'.TB_AUTHORITY_TYPES ATO, '||v_schema2_name||'.TB_MERCHANTS M, '||v_schema2_name||'.TB_PRODUCT_GROUPS PG, '||v_schema2_name||'.TB_PRODUCT_GROUPS PGO
      WHERE A.CHANGE_DATE > '''||v_change_date_after2||'''
      AND A.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.MERCHANT_ID = COALESCE(A.MERCHANT_ID,A.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND A.ADMIN_ZONE_LEVEL_ID = ZL.ZONE_LEVEL_ID(+)
      AND A.EFFECTIVE_ZONE_LEVEL_ID = ZE.ZONE_LEVEL_ID(+)
      AND A.AUTHORITY_TYPE_ID = AT.AUTHORITY_TYPE_ID(+)
      AND A.AUTHORITY_TYPE_ID_O = ATO.AUTHORITY_TYPE_ID(+)
      AND A.EFFECTIVE_ZONE_LEVEL_ID_O = ZEO.ZONE_LEVEL_ID(+)
      AND A.ADMIN_ZONE_LEVEL_ID_O = ZLO.ZONE_LEVEL_ID(+)
      AND A.PRODUCT_GROUP_ID = PG.PRODUCT_GROUP_ID(+)
      AND A.PRODUCT_GROUP_ID_O = PGO.PRODUCT_GROUP_ID(+)
      MINUS
     select ''Change Only in '||v_system2_name||''' "CHANGE LOCATION", a.change_type "OPERATION TYPE",      A.NAME_O "OLD NAME",      a.NAME "NAME",     
      A.OFFICIAL_NAME_O "OLD OFFICIAL NAME",      A.OFFICIAL_NAME "OFFICIAL NAME",      A.AUTHORITY_CATEGORY_O "OLD AUTHORITY CATEGORY",      A.AUTHORITY_CATEGORY "AUTHORITY CATEGORY",      A.INVOICE_DESCRIPTION_O "OLD INVOICE DESCRIPTION",
      A.INVOICE_DESCRIPTION "INVOICE DESCRIPTION",      A.REGION_CODE_O "OLD AUTHORITY FIPS",      A.REGION_CODE "AUTHORITY FIPS",      A.DESCRIPTION_O "OLD DESCRIPTION",      A.DESCRIPTION "DESCRIPTION",
      ATO.NAME "OLD AUTHORITY TYPE",      AT.NAME "AUTHORITY TYPE",      A.REGISTRATION_MASK_O "OLD REGISTRATION MASK",      a.REGISTRATION_MASK "REGISTRATION MASK",      A.SIMPLE_REGISTRATION_MASK_O "OLD SIMPLE REG MASK",
      a.SIMPLE_REGISTRATION_MASK "SIMPLE REG MASK",      A.LOCATION_CODE_O "OLD LOCATION CODE",      a.LOCATION_CODE "LOCATION CODE",      A.DISTANCE_SALES_THRESHOLD_O "OLD DISTANCE THRESHOLD",      A.DISTANCE_SALES_THRESHOLD "DISTANCE THRESHOLD",
      A.CONTENT_TYPE_O "OLD CONTENT TYPE",      A.CONTENT_TYPE "CONTENT TYPE",      PGO.NAME "OLD PRODUCT GROUP",      PG.NAME "PRODUCT GROUP",      ZLO.NAME "OLD ADMIN LEVEL",
      ZL.NAME "ADMIN LEVEL",      ZEO.NAME "OLD EFFECTIVE LEVEL",      ZE.NAME "EFFECTIVE LEVEL"
      from '||v_schema1_name||'.A_authorities A, '||v_schema1_name||'.TB_ZONE_LEVELS ZL, '||v_schema1_name||'.TB_ZONE_LEVELS ZE, '||v_schema1_name||'.TB_AUTHORITY_TYPES AT, '||v_schema1_name||'.TB_ZONE_LEVELS ZLO,
      '||v_schema1_name||'.TB_ZONE_LEVELS ZEO, '||v_schema1_name||'.TB_AUTHORITY_TYPES ATO, '||v_schema1_name||'.TB_MERCHANTS M, '||v_schema1_name||'.TB_PRODUCT_GROUPS PG, '||v_schema1_name||'.TB_PRODUCT_GROUPS PGO
      WHERE A.CHANGE_DATE > '''||v_change_date_after||'''
      AND A.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.MERCHANT_ID = COALESCE(A.MERCHANT_ID,A.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND A.ADMIN_ZONE_LEVEL_ID = ZL.ZONE_LEVEL_ID(+)
      AND A.EFFECTIVE_ZONE_LEVEL_ID = ZE.ZONE_LEVEL_ID(+)
      AND A.AUTHORITY_TYPE_ID = AT.AUTHORITY_TYPE_ID(+)
      AND A.AUTHORITY_TYPE_ID_O = ATO.AUTHORITY_TYPE_ID(+)
      AND A.EFFECTIVE_ZONE_LEVEL_ID_O = ZEO.ZONE_LEVEL_ID(+)
      AND A.ADMIN_ZONE_LEVEL_ID_O = ZLO.ZONE_LEVEL_ID(+)
      AND A.PRODUCT_GROUP_ID = PG.PRODUCT_GROUP_ID(+)
      AND A.PRODUCT_GROUP_ID_O = PGO.PRODUCT_GROUP_ID(+)
      ) 
      ORDER BY 2, 5');
      DBMS_OUTPUT.PUT_LINE('AUTHORITY COMPLETE');
    end_worksheet;
    start_worksheet('CONTRIBUTING AUTHORITIES');
    run_query('
    (
      SELECT ''Change Only in '||v_system1_name||''' "CHANGE LOCATION",CA.CHANGE_TYPE "OPERATION TYPE",      A_FROM_O.NAME "OLD FROM AUTHORITY",      A_FROM.NAME "FROM AUTHORITY",      A_TO_O.NAME "OLD TO AUTHORITY",
      A_TO.NAME "TO AUTHORITY",      CA.BASIS_PERCENT_O "OLD BASIS PERCENT",      CA.BASIS_PERCENT "BASIS PERCENT",      CA.START_DATE_O "OLD START DATE",      CA.START_DATE "START DATE",
      CA.END_DATE_O "OLD END DATE",      CA.END_DATE "END DATE"
      FROM '||v_schema1_name||'.A_CONTRIBUTING_AUTHORITIES CA, '||v_schema1_name||'.TB_MERCHANTS M, '||v_schema1_name||'.TB_AUTHORITIES A_FROM, '||v_schema1_name||'.TB_AUTHORITIES A_TO, '||v_schema1_name||'.TB_AUTHORITIES A_FROM_O, '||v_schema1_name||'.TB_AUTHORITIES A_TO_O
      WHERE CA.CHANGE_DATE > '''||v_change_date_after||'''
      AND CA.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.MERCHANT_ID = COALESCE(CA.MERCHANT_ID,CA.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND CA.AUTHORITY_ID_O = A_TO_O.AUTHORITY_ID(+)
      AND CA.AUTHORITY_ID = A_TO.AUTHORITY_ID(+)
      AND CA.THIS_AUTHORITY_ID = A_FROM.AUTHORITY_ID(+)
      AND CA.THIS_AUTHORITY_ID_O = A_FROM_O.AUTHORITY_ID(+)
      MINUS
      SELECT ''Change Only in '||v_system1_name||''' "CHANGE LOCATION",CA.CHANGE_TYPE "OPERATION TYPE",      A_FROM_O.NAME "OLD FROM AUTHORITY",      A_FROM.NAME "FROM AUTHORITY",      A_TO_O.NAME "OLD TO AUTHORITY",
      A_TO.NAME "TO AUTHORITY",      CA.BASIS_PERCENT_O "OLD BASIS PERCENT",      CA.BASIS_PERCENT "BASIS PERCENT",      CA.START_DATE_O "OLD START DATE",      CA.START_DATE "START DATE",
      CA.END_DATE_O "OLD END DATE",      CA.END_DATE "END DATE"
      FROM '||v_schema2_name||'.A_CONTRIBUTING_AUTHORITIES CA, '||v_schema2_name||'.TB_MERCHANTS M, '||v_schema2_name||'.TB_AUTHORITIES A_FROM, '||v_schema2_name||'.TB_AUTHORITIES A_TO, '||v_schema2_name||'.TB_AUTHORITIES A_FROM_O, '||v_schema2_name||'.TB_AUTHORITIES A_TO_O
      WHERE CA.CHANGE_DATE > '''||v_change_date_after2||'''
      AND CA.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.MERCHANT_ID = COALESCE(CA.MERCHANT_ID,CA.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND CA.AUTHORITY_ID_O = A_TO_O.AUTHORITY_ID(+)
      AND CA.AUTHORITY_ID = A_TO.AUTHORITY_ID(+)
      AND CA.THIS_AUTHORITY_ID = A_FROM.AUTHORITY_ID(+)
      AND CA.THIS_AUTHORITY_ID_O = A_FROM_O.AUTHORITY_ID(+)
      )
      UNION ALL
      (
      SELECT ''Change Only in '||v_system2_name||''' "CHANGE LOCATION",CA.CHANGE_TYPE "OPERATION TYPE",      A_FROM_O.NAME "OLD FROM AUTHORITY",      A_FROM.NAME "FROM AUTHORITY",      A_TO_O.NAME "OLD TO AUTHORITY",
      A_TO.NAME "TO AUTHORITY",      CA.BASIS_PERCENT_O "OLD BASIS PERCENT",      CA.BASIS_PERCENT "BASIS PERCENT",      CA.START_DATE_O "OLD START DATE",      CA.START_DATE "START DATE",
      CA.END_DATE_O "OLD END DATE",      CA.END_DATE "END DATE"
      FROM '||v_schema2_name||'.A_CONTRIBUTING_AUTHORITIES CA, '||v_schema2_name||'.TB_MERCHANTS M, '||v_schema2_name||'.TB_AUTHORITIES A_FROM, '||v_schema2_name||'.TB_AUTHORITIES A_TO, '||v_schema2_name||'.TB_AUTHORITIES A_FROM_O, '||v_schema2_name||'.TB_AUTHORITIES A_TO_O
      WHERE CA.CHANGE_DATE > '''||v_change_date_after2||'''
      AND CA.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.MERCHANT_ID = COALESCE(CA.MERCHANT_ID,CA.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND CA.AUTHORITY_ID_O = A_TO_O.AUTHORITY_ID(+)
      AND CA.AUTHORITY_ID = A_TO.AUTHORITY_ID(+)
      AND CA.THIS_AUTHORITY_ID = A_FROM.AUTHORITY_ID(+)
      AND CA.THIS_AUTHORITY_ID_O = A_FROM_O.AUTHORITY_ID(+)
      MINUS
      SELECT ''Change Only in '||v_system2_name||''' "CHANGE LOCATION",CA.CHANGE_TYPE "OPERATION TYPE",      A_FROM_O.NAME "OLD FROM AUTHORITY",      A_FROM.NAME "FROM AUTHORITY",      A_TO_O.NAME "OLD TO AUTHORITY",
      A_TO.NAME "TO AUTHORITY",      CA.BASIS_PERCENT_O "OLD BASIS PERCENT",      CA.BASIS_PERCENT "BASIS PERCENT",      CA.START_DATE_O "OLD START DATE",      CA.START_DATE "START DATE",
      CA.END_DATE_O "OLD END DATE",      CA.END_DATE "END DATE"
      FROM '||v_schema1_name||'.A_CONTRIBUTING_AUTHORITIES CA, '||v_schema1_name||'.TB_MERCHANTS M, '||v_schema1_name||'.TB_AUTHORITIES A_FROM, '||v_schema1_name||'.TB_AUTHORITIES A_TO, '||v_schema1_name||'.TB_AUTHORITIES A_FROM_O, '||v_schema1_name||'.TB_AUTHORITIES A_TO_O
      WHERE CA.CHANGE_DATE > '''||v_change_date_after||'''
      AND CA.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.MERCHANT_ID = COALESCE(CA.MERCHANT_ID,CA.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND CA.AUTHORITY_ID_O = A_TO_O.AUTHORITY_ID(+)
      AND CA.AUTHORITY_ID = A_TO.AUTHORITY_ID(+)
      AND CA.THIS_AUTHORITY_ID = A_FROM.AUTHORITY_ID(+)
      AND CA.THIS_AUTHORITY_ID_O = A_FROM_O.AUTHORITY_ID(+)
      )
      ORDER BY 2, 5, 7');
      DBMS_OUTPUT.PUT_LINE('CONTRIBUTING AUTHORITY COMPLETE');
    end_worksheet;
    start_worksheet('AUTHORITY OPTIONS');
    run_query('
    (
    SELECT ''Change Only in '||v_system1_name||''' "CHANGE LOCATION",AR.CHANGE_TYPE "OPERATION TYPE",      A.NAME "AUTHORITY",     LO.DESCRIPTION "OLD DESCRIPTION",      L.DESCRIPTION "DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_COND'' AND CODE = AR.CONDITION_O) "OLD CONDITION DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_COND'' AND CODE = AR.CONDITION) "CONDITION DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_VALUE'' AND CODE = AR.VALUE_O) "OLD VALUE DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_VALUE'' AND CODE = AR.VALUE) "VALUE DESCRIPTION",
      AR.START_DATE_O "OLD START DATE",      AR.START_DATE "START DATE",      AR.END_DATE_O "OLD END DATE",      AR.END_DATE "END DATE"
      FROM '||v_schema1_name||'.A_AUTHORITY_REQUIREMENTS AR, '||v_schema1_name||'.TB_MERCHANTS M, '||v_schema1_name||'.TB_AUTHORITIES A, '||v_schema1_name||'.TB_LOOKUPS L, '||v_schema1_name||'.TB_LOOKUPS LO
      WHERE AR.CHANGE_DATE > '''||v_change_date_after||'''
      AND AR.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.MERCHANT_ID = COALESCE(AR.MERCHANT_ID,AR.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND COALESCE(AR.AUTHORITY_ID,AR.AUTHORITY_ID_O) = A.AUTHORITY_ID
      AND AR.NAME_O = LO.CODE(+)
      AND nvl(LO.CODE_GROUP,''AUTH_REQ_NAME'') = ''AUTH_REQ_NAME''
      AND AR.NAME = L.CODE(+)
      AND L.CODE_GROUP = ''AUTH_REQ_NAME''
      MINUS
          SELECT ''Change Only in '||v_system1_name||''' "CHANGE LOCATION",AR.CHANGE_TYPE "OPERATION TYPE",      A.NAME "AUTHORITY",     LO.DESCRIPTION "OLD DESCRIPTION",      L.DESCRIPTION "DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_COND'' AND CODE = AR.CONDITION_O) "OLD CONDITION DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_COND'' AND CODE = AR.CONDITION) "CONDITION DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_VALUE'' AND CODE = AR.VALUE_O) "OLD VALUE DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_VALUE'' AND CODE = AR.VALUE) "VALUE DESCRIPTION",
      AR.START_DATE_O "OLD START DATE",      AR.START_DATE "START DATE",      AR.END_DATE_O "OLD END DATE",      AR.END_DATE "END DATE"
      FROM '||v_schema2_name||'.A_AUTHORITY_REQUIREMENTS AR, '||v_schema2_name||'.TB_MERCHANTS M, '||v_schema2_name||'.TB_AUTHORITIES A, '||v_schema2_name||'.TB_LOOKUPS L, '||v_schema2_name||'.TB_LOOKUPS LO
      WHERE AR.CHANGE_DATE > '''||v_change_date_after2||'''
      AND AR.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.MERCHANT_ID = COALESCE(AR.MERCHANT_ID,AR.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND COALESCE(AR.AUTHORITY_ID,AR.AUTHORITY_ID_O) = A.AUTHORITY_ID
      AND AR.NAME_O = LO.CODE(+)
      AND nvl(LO.CODE_GROUP,''AUTH_REQ_NAME'') = ''AUTH_REQ_NAME''
      AND AR.NAME = L.CODE(+)
      AND L.CODE_GROUP = ''AUTH_REQ_NAME''
      )
      UNION ALL
      (
      SELECT ''Change Only in '||v_system2_name||''' "CHANGE LOCATION",AR.CHANGE_TYPE "OPERATION TYPE",      A.NAME "AUTHORITY",     LO.DESCRIPTION "OLD DESCRIPTION",      L.DESCRIPTION "DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_COND'' AND CODE = AR.CONDITION_O) "OLD CONDITION DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_COND'' AND CODE = AR.CONDITION) "CONDITION DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_VALUE'' AND CODE = AR.VALUE_O) "OLD VALUE DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_VALUE'' AND CODE = AR.VALUE) "VALUE DESCRIPTION",
      AR.START_DATE_O "OLD START DATE",      AR.START_DATE "START DATE",      AR.END_DATE_O "OLD END DATE",      AR.END_DATE "END DATE"
      FROM '||v_schema2_name||'.A_AUTHORITY_REQUIREMENTS AR, '||v_schema2_name||'.TB_MERCHANTS M, '||v_schema2_name||'.TB_AUTHORITIES A, '||v_schema2_name||'.TB_LOOKUPS L, '||v_schema2_name||'.TB_LOOKUPS LO
      WHERE AR.CHANGE_DATE > '''||v_change_date_after2||'''
      AND AR.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.MERCHANT_ID = COALESCE(AR.MERCHANT_ID,AR.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND COALESCE(AR.AUTHORITY_ID,AR.AUTHORITY_ID_O) = A.AUTHORITY_ID
      AND AR.NAME_O = LO.CODE(+)
      AND nvl(LO.CODE_GROUP,''AUTH_REQ_NAME'') = ''AUTH_REQ_NAME''
      AND AR.NAME = L.CODE(+)
      AND L.CODE_GROUP = ''AUTH_REQ_NAME'' 
      MINUS
      SELECT ''Change Only in '||v_system2_name||''' "CHANGE LOCATION",AR.CHANGE_TYPE "OPERATION TYPE",      A.NAME "AUTHORITY",     LO.DESCRIPTION "OLD DESCRIPTION",      L.DESCRIPTION "DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_COND'' AND CODE = AR.CONDITION_O) "OLD CONDITION DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_COND'' AND CODE = AR.CONDITION) "CONDITION DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_VALUE'' AND CODE = AR.VALUE_O) "OLD VALUE DESCRIPTION",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE code_group = ''AUTH_REQ_VALUE'' AND CODE = AR.VALUE) "VALUE DESCRIPTION",
      AR.START_DATE_O "OLD START DATE",      AR.START_DATE "START DATE",      AR.END_DATE_O "OLD END DATE",      AR.END_DATE "END DATE"
      FROM '||v_schema1_name||'.A_AUTHORITY_REQUIREMENTS AR, '||v_schema1_name||'.TB_MERCHANTS M, '||v_schema1_name||'.TB_AUTHORITIES A, '||v_schema1_name||'.TB_LOOKUPS L, '||v_schema1_name||'.TB_LOOKUPS LO
      WHERE AR.CHANGE_DATE > '''||v_change_date_after||'''
      AND AR.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.MERCHANT_ID = COALESCE(AR.MERCHANT_ID,AR.MERCHANT_ID_O)
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND COALESCE(AR.AUTHORITY_ID,AR.AUTHORITY_ID_O) = A.AUTHORITY_ID
      AND AR.NAME_O = LO.CODE(+)
      AND nvl(LO.CODE_GROUP,''AUTH_REQ_NAME'') = ''AUTH_REQ_NAME''
      AND AR.NAME = L.CODE(+)
      AND L.CODE_GROUP = ''AUTH_REQ_NAME''
      )    
      ORDER BY 2, 4');
    DBMS_OUTPUT.PUT_LINE('AUTHORITY OPITONS COMPLETE');
    end_worksheet;
    --start_worksheet('AUTHORITY SPECIFIC MESSAGES');
    --end_worksheet;
    start_worksheet('RATES');
    run_query('
    (
SELECT ''Change only in '||v_system1_name||''' "CHANGE LOCATION", COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) "OPERATION_TYPE",      
      COALESCE(R.CHANGE_DATE,RT.CHANGE_DATE) "CHANGE DATE",
      COALESCE(A.NAME,AE.NAME) "AUTHORITY NAME", 
      R.DESCRIPTION_O "OLD RATE DESCRIPTION", 
      COALESCE(R.DESCRIPTION,RE.DESCRIPTION) "RATE DESCRIPTION", 
      R.RATE_CODE_O "OLD RATE CODE", 
      COALESCE(R.RATE_CODE,RE.RATE_CODE) "RATE CODE", 
      R.RATE_O "OLD RATE", 
      COALESCE(R.RATE,RE.RATE) "RATE", 
      R.FLAT_FEE_O "OLD FEE", 
      COALESCE(R.FLAT_FEE,RE.FLAT_FEE) "FEE", 
      CASE R.SPLIT_TYPE_O 
        WHEN ''R'' THEN ''Tiered'' 
        WHEN ''G'' THEN ''Graduated'' 
        WHEN ''T'' THEN ''Texas City/Cnty Max'' 
        ELSE DECODE(COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE), ''CREATED'', NULL, ''Basic'') 
        END AS "OLD TIER TYPE", 
      CASE COALESCE(R.SPLIT_TYPE,RE.SPLIT_TYPE)
        WHEN ''R'' THEN ''Tiered'' 
        WHEN ''G'' THEN ''Graduated'' 
        WHEN ''T'' THEN ''Texas City/Cnty Max'' 
        ELSE DECODE(COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE), ''DELETED'', NULL, ''Basic'') 
        END AS "TIER TYPE", 
      R.START_DATE_O "OLD START DATE", 
      COALESCE(R.START_DATE,RE.START_DATE) "START DATE", 
      R.END_DATE_O "OLD END DATE", 
      COALESCE(R.END_DATE,RE.END_DATE) "END DATE", 
      R.IS_LOCAL_O "OLD CASCADING", 
      COALESCE(R.IS_LOCAL,RE.IS_LOCAL) "CASCADING",
      R.UNIT_OF_MEASURE_CODE_O "OLD UNIT OF MEASURE", 
      COALESCE(R.UNIT_OF_MEASURE_CODE,RE.UNIT_OF_MEASURE_CODE) "UNIT OF MEASURE",
      CO.NAME "OLD CURRENCY", 
      C.NAME "CURRENCY", 
      CASE R.SPLIT_AMOUNT_TYPE_O 
        WHEN ''P'' THEN ''Invoice Amount By Rule'' 
        WHEN ''L'' THEN ''Line Amount'' 
        WHEN ''I'' THEN ''Invoice Amount'' 
        WHEN ''T'' THEN ''Item Amount'' 
        WHEN ''Q'' THEN ''Quantity'' 
        END AS "OLD TIER AMOUNT TYPE", 
      CASE COALESCE(R.SPLIT_AMOUNT_TYPE,RE.SPLIT_AMOUNT_TYPE)
        WHEN ''P'' THEN ''Invoice Amount By Rule'' 
        WHEN ''L'' THEN ''Line Amount'' 
        WHEN ''I'' THEN ''Invoice Amount'' 
        WHEN ''T'' THEN ''Item Amount'' 
        WHEN ''Q'' THEN ''Quantity'' 
        END AS "TIER AMOUNT TYPE", 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE coalesce(RT.AMOUNT_LOW_O,RTE.AMOUNT_LOW)
        END AS "OLD AMOUNT LOW", 
      COALESCE(RT.AMOUNT_LOW, RTE.AMOUNT_LOW) "AMOUNT LOW", --Prefer audited change over existing value 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RT.AMOUNT_HIGH_O,RTE.AMOUNT_HIGH)
        END AS "OLD AMOUNT HIGH", 
      coalesce(RT.AMOUNT_HIGH, RTE.AMOUNT_HIGH) "AMOUNT HIGH",
      CASE COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE)
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RT.RATE_O, RTE.RATE) 
        END AS "OLD TIERED RATE",
      coalesce(RT.RATE, RTE.RATE) "TIERED RATE", 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RT.RATE_CODE_O, RTE.RATE_CODE)
        END AS "OLD REFERENCED RATE CODE", 
      COALESCE(RT.RATE_CODE, RTE.RATE_CODE) "REFERENCED RATE CODE" 
      FROM '||v_schema1_name||'.A_RATES R 
      JOIN '||v_schema1_name||'.TB_AUTHORITIES A ON (A.AUTHORITY_ID = COALESCE(R.AUTHORITY_ID,R.AUTHORITY_ID_O)) 
      JOIN '||v_schema1_name||'.TB_MERCHANTS M ON (M.MERCHANT_ID = A.MERCHANT_ID) 
      FULL outer JOIN '||v_schema1_name||'.A_RATE_TIERS RT ON (COALESCE(RT.RATE_ID,RT.RATE_ID_O) = COALESCE(R.RATE_ID,R.RATE_ID_O) AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'') --IF CREATED THEN PREFER R AND RTE AND IF IT IS NOT ONLY A RATE CHANGE
      LEFT join '||v_schema1_name||'.TB_RATE_TIERS RTE ON (RTE.RATE_ID = COALESCE(R.RATE_ID,R.RATE_ID_O) AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''-UPDATED'') --IF IT IS ONLY A RATE TIER CHANGE DON''T GO FIND THESE TIERS
      LEFT JOIN '||v_schema1_name||'.TB_RATES RE ON (RE.RATE_ID = COALESCE(RT.RATE_ID,RT.RATE_ID_O) AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'') 
      LEFT JOIN '||v_schema1_name||'.TB_AUTHORITIES AE ON (AE.AUTHORITY_ID = RE.AUTHORITY_ID AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema1_name||'.TB_CURRENCIES C ON (C.CURRENCY_ID = COALESCE(R.CURRENCY_ID,RE.CURRENCY_ID)) 
      LEFT JOIN '||v_schema1_name||'.TB_CURRENCIES CO ON (CO.CURRENCY_ID = R.CURRENCY_ID_O) 
      WHERE COALESCE(R.CHANGE_DATE, RT.CHANGE_DATE) > '''||v_change_date_after||'''
      AND COALESCE(R.CHANGE_DATE, RT.CHANGE_DATE) < '''||v_change_date_before||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
MINUS
SELECT ''Change only in '||v_system1_name||''' "CHANGE LOCATION", COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) "OPERATION_TYPE",       
      COALESCE(R.CHANGE_DATE,RT.CHANGE_DATE) "CHANGE DATE",
      COALESCE(A.NAME,AE.NAME) "AUTHORITY NAME", 
      R.DESCRIPTION_O "OLD RATE DESCRIPTION", 
      COALESCE(R.DESCRIPTION,RE.DESCRIPTION) "RATE DESCRIPTION", 
      R.RATE_CODE_O "OLD RATE CODE", 
      COALESCE(R.RATE_CODE,RE.RATE_CODE) "RATE CODE", 
      R.RATE_O "OLD RATE", 
      COALESCE(R.RATE,RE.RATE) "RATE", 
      R.FLAT_FEE_O "OLD FEE", 
      COALESCE(R.FLAT_FEE,RE.FLAT_FEE) "FEE", 
      CASE R.SPLIT_TYPE_O 
        WHEN ''R'' THEN ''Tiered'' 
        WHEN ''G'' THEN ''Graduated'' 
        WHEN ''T'' THEN ''Texas City/Cnty Max'' 
        ELSE DECODE(COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE), ''CREATED'', NULL, ''Basic'') 
        END AS "OLD TIER TYPE", 
      CASE COALESCE(R.SPLIT_TYPE,RE.SPLIT_TYPE)
        WHEN ''R'' THEN ''Tiered'' 
        WHEN ''G'' THEN ''Graduated'' 
        WHEN ''T'' THEN ''Texas City/Cnty Max'' 
        ELSE DECODE(COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE), ''DELETED'', NULL, ''Basic'') 
        END AS "TIER TYPE", 
      R.START_DATE_O "OLD START DATE", 
      COALESCE(R.START_DATE,RE.START_DATE) "START DATE", 
      R.END_DATE_O "OLD END DATE", 
      COALESCE(R.END_DATE,RE.END_DATE) "END DATE", 
      R.IS_LOCAL_O "OLD CASCADING", 
      COALESCE(R.IS_LOCAL,RE.IS_LOCAL) "CASCADING",
      R.UNIT_OF_MEASURE_CODE_O "OLD UNIT OF MEASURE", 
      COALESCE(R.UNIT_OF_MEASURE_CODE,RE.UNIT_OF_MEASURE_CODE) "UNIT OF MEASURE",
      CO.NAME "OLD CURRENCY", 
      C.NAME "CURRENCY", 
      CASE R.SPLIT_AMOUNT_TYPE_O 
        WHEN ''P'' THEN ''Invoice Amount By Rule'' 
        WHEN ''L'' THEN ''Line Amount'' 
        WHEN ''I'' THEN ''Invoice Amount'' 
        WHEN ''T'' THEN ''Item Amount'' 
        WHEN ''Q'' THEN ''Quantity'' 
        END AS "OLD TIER AMOUNT TYPE", 
      CASE COALESCE(R.SPLIT_AMOUNT_TYPE,RE.SPLIT_AMOUNT_TYPE)
        WHEN ''P'' THEN ''Invoice Amount By Rule'' 
        WHEN ''L'' THEN ''Line Amount'' 
        WHEN ''I'' THEN ''Invoice Amount'' 
        WHEN ''T'' THEN ''Item Amount'' 
        WHEN ''Q'' THEN ''Quantity'' 
        END AS "TIER AMOUNT TYPE", 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE coalesce(RT.AMOUNT_LOW_O,RTE.AMOUNT_LOW)
        END AS "OLD AMOUNT LOW", 
      COALESCE(RT.AMOUNT_LOW, RTE.AMOUNT_LOW) "AMOUNT LOW", --Prefer audited change over existing value 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RT.AMOUNT_HIGH_O,RTE.AMOUNT_HIGH)
        END AS "OLD AMOUNT HIGH", 
      coalesce(RT.AMOUNT_HIGH, RTE.AMOUNT_HIGH) "AMOUNT HIGH",
      CASE COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE)
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RT.RATE_O, RTE.RATE) 
        END AS "OLD TIERED RATE",
      coalesce(RT.RATE, RTE.RATE) "TIERED RATE", 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RT.RATE_CODE_O, RTE.RATE_CODE)
        END AS "OLD REFERENCED RATE CODE", 
      COALESCE(RT.RATE_CODE, RTE.RATE_CODE) "REFERENCED RATE CODE" 
      FROM '||v_schema2_name||'.A_RATES R 
      JOIN '||v_schema2_name||'.TB_AUTHORITIES A ON (A.AUTHORITY_ID = COALESCE(R.AUTHORITY_ID,R.AUTHORITY_ID_O)) 
      JOIN '||v_schema2_name||'.TB_MERCHANTS M ON (M.MERCHANT_ID = A.MERCHANT_ID) 
      FULL outer JOIN '||v_schema2_name||'.A_RATE_TIERS RT ON (COALESCE(RT.RATE_ID,RT.RATE_ID_O) = COALESCE(R.RATE_ID,R.RATE_ID_O) AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'') --IF CREATED THEN PREFER R AND RTE AND IF IT IS NOT ONLY A RATE CHANGE
      LEFT join '||v_schema2_name||'.TB_RATE_TIERS RTE ON (RTE.RATE_ID = COALESCE(R.RATE_ID,R.RATE_ID_O) AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''-UPDATED'') --IF IT IS ONLY A RATE TIER CHANGE DON''T GO FIND THESE TIERS
      LEFT JOIN '||v_schema2_name||'.TB_RATES RE ON (RE.RATE_ID = COALESCE(RT.RATE_ID,RT.RATE_ID_O) AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'') 
      LEFT JOIN '||v_schema2_name||'.TB_AUTHORITIES AE ON (AE.AUTHORITY_ID = RE.AUTHORITY_ID AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema2_name||'.TB_CURRENCIES C ON (C.CURRENCY_ID = COALESCE(R.CURRENCY_ID,RE.CURRENCY_ID)) 
      LEFT JOIN '||v_schema2_name||'.TB_CURRENCIES CO ON (CO.CURRENCY_ID = R.CURRENCY_ID_O) 
      WHERE COALESCE(R.CHANGE_DATE, RT.CHANGE_DATE) > '''||v_change_date_after2||'''
      AND COALESCE(R.CHANGE_DATE, RT.CHANGE_DATE) < '''||v_change_date_before2||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
)
UNION ALL
  (
 SELECT ''Change only in '||v_system2_name||''' "CHANGE LOCATION", COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) "OPERATION_TYPE",       
      COALESCE(R.CHANGE_DATE,RT.CHANGE_DATE) "CHANGE DATE",
      COALESCE(A.NAME,AE.NAME) "AUTHORITY NAME", 
      R.DESCRIPTION_O "OLD RATE DESCRIPTION", 
      COALESCE(R.DESCRIPTION,RE.DESCRIPTION) "RATE DESCRIPTION", 
      R.RATE_CODE_O "OLD RATE CODE", 
      COALESCE(R.RATE_CODE,RE.RATE_CODE) "RATE CODE", 
      R.RATE_O "OLD RATE", 
      COALESCE(R.RATE,RE.RATE) "RATE", 
      R.FLAT_FEE_O "OLD FEE", 
      COALESCE(R.FLAT_FEE,RE.FLAT_FEE) "FEE", 
      CASE R.SPLIT_TYPE_O 
        WHEN ''R'' THEN ''Tiered'' 
        WHEN ''G'' THEN ''Graduated'' 
        WHEN ''T'' THEN ''Texas City/Cnty Max'' 
        ELSE DECODE(COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE), ''CREATED'', NULL, ''Basic'') 
        END AS "OLD TIER TYPE", 
      CASE COALESCE(R.SPLIT_TYPE,RE.SPLIT_TYPE)
        WHEN ''R'' THEN ''Tiered'' 
        WHEN ''G'' THEN ''Graduated'' 
        WHEN ''T'' THEN ''Texas City/Cnty Max'' 
        ELSE DECODE(COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE), ''DELETED'', NULL, ''Basic'') 
        END AS "TIER TYPE", 
      R.START_DATE_O "OLD START DATE", 
      COALESCE(R.START_DATE,RE.START_DATE) "START DATE", 
      R.END_DATE_O "OLD END DATE", 
      COALESCE(R.END_DATE,RE.END_DATE) "END DATE", 
      R.IS_LOCAL_O "OLD CASCADING", 
      COALESCE(R.IS_LOCAL,RE.IS_LOCAL) "CASCADING",
      R.UNIT_OF_MEASURE_CODE_O "OLD UNIT OF MEASURE", 
      COALESCE(R.UNIT_OF_MEASURE_CODE,RE.UNIT_OF_MEASURE_CODE) "UNIT OF MEASURE",
      CO.NAME "OLD CURRENCY", 
      C.NAME "CURRENCY", 
      CASE R.SPLIT_AMOUNT_TYPE_O 
        WHEN ''P'' THEN ''Invoice Amount By Rule'' 
        WHEN ''L'' THEN ''Line Amount'' 
        WHEN ''I'' THEN ''Invoice Amount'' 
        WHEN ''T'' THEN ''Item Amount'' 
        WHEN ''Q'' THEN ''Quantity'' 
        END AS "OLD TIER AMOUNT TYPE", 
      CASE COALESCE(R.SPLIT_AMOUNT_TYPE,RE.SPLIT_AMOUNT_TYPE)
        WHEN ''P'' THEN ''Invoice Amount By Rule'' 
        WHEN ''L'' THEN ''Line Amount'' 
        WHEN ''I'' THEN ''Invoice Amount'' 
        WHEN ''T'' THEN ''Item Amount'' 
        WHEN ''Q'' THEN ''Quantity'' 
        END AS "TIER AMOUNT TYPE", 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE coalesce(RT.AMOUNT_LOW_O,RTE.AMOUNT_LOW)
        END AS "OLD AMOUNT LOW", 
      COALESCE(RT.AMOUNT_LOW, RTE.AMOUNT_LOW) "AMOUNT LOW", --Prefer audited change over existing value 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RT.AMOUNT_HIGH_O,RTE.AMOUNT_HIGH)
        END AS "OLD AMOUNT HIGH", 
      coalesce(RT.AMOUNT_HIGH, RTE.AMOUNT_HIGH) "AMOUNT HIGH",
      CASE COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE)
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RT.RATE_O, RTE.RATE) 
        END AS "OLD TIERED RATE",
      coalesce(RT.RATE, RTE.RATE) "TIERED RATE", 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RT.RATE_CODE_O, RTE.RATE_CODE)
        END AS "OLD REFERENCED RATE CODE", 
      COALESCE(RT.RATE_CODE, RTE.RATE_CODE) "REFERENCED RATE CODE" 
      FROM '||v_schema2_name||'.A_RATES R 
      JOIN '||v_schema2_name||'.TB_AUTHORITIES A ON (A.AUTHORITY_ID = COALESCE(R.AUTHORITY_ID,R.AUTHORITY_ID_O)) 
      JOIN '||v_schema2_name||'.TB_MERCHANTS M ON (M.MERCHANT_ID = A.MERCHANT_ID) 
      FULL outer JOIN '||v_schema2_name||'.A_RATE_TIERS RT ON (COALESCE(RT.RATE_ID,RT.RATE_ID_O) = COALESCE(R.RATE_ID,R.RATE_ID_O) AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'') --IF CREATED THEN PREFER R AND RTE AND IF IT IS NOT ONLY A RATE CHANGE
      LEFT join '||v_schema2_name||'.TB_RATE_TIERS RTE ON (RTE.RATE_ID = COALESCE(R.RATE_ID,R.RATE_ID_O) AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''-UPDATED'') --IF IT IS ONLY A RATE TIER CHANGE DON''T GO FIND THESE TIERS
      LEFT JOIN '||v_schema2_name||'.TB_RATES RE ON (RE.RATE_ID = COALESCE(RT.RATE_ID,RT.RATE_ID_O) AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'') 
      LEFT JOIN '||v_schema2_name||'.TB_AUTHORITIES AE ON (AE.AUTHORITY_ID = RE.AUTHORITY_ID AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema2_name||'.TB_CURRENCIES C ON (C.CURRENCY_ID = COALESCE(R.CURRENCY_ID,RE.CURRENCY_ID)) 
      LEFT JOIN '||v_schema2_name||'.TB_CURRENCIES CO ON (CO.CURRENCY_ID = R.CURRENCY_ID_O) 
      WHERE COALESCE(R.CHANGE_DATE, RT.CHANGE_DATE) > '''||v_change_date_after2||'''
      AND COALESCE(R.CHANGE_DATE, RT.CHANGE_DATE) < '''||v_change_date_before2||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
MINUS
 SELECT ''Change only in '||v_system2_name||''' "CHANGE LOCATION", COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) "OPERATION_TYPE",       
      COALESCE(R.CHANGE_DATE,RT.CHANGE_DATE) "CHANGE DATE",
      COALESCE(A.NAME,AE.NAME) "AUTHORITY NAME", 
      R.DESCRIPTION_O "OLD RATE DESCRIPTION", 
      COALESCE(R.DESCRIPTION,RE.DESCRIPTION) "RATE DESCRIPTION", 
      R.RATE_CODE_O "OLD RATE CODE", 
      COALESCE(R.RATE_CODE,RE.RATE_CODE) "RATE CODE", 
      R.RATE_O "OLD RATE", 
      COALESCE(R.RATE,RE.RATE) "RATE", 
      R.FLAT_FEE_O "OLD FEE", 
      COALESCE(R.FLAT_FEE,RE.FLAT_FEE) "FEE", 
      CASE R.SPLIT_TYPE_O 
        WHEN ''R'' THEN ''Tiered'' 
        WHEN ''G'' THEN ''Graduated'' 
        WHEN ''T'' THEN ''Texas City/Cnty Max'' 
        ELSE DECODE(COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE), ''CREATED'', NULL, ''Basic'') 
        END AS "OLD TIER TYPE", 
      CASE COALESCE(R.SPLIT_TYPE,RE.SPLIT_TYPE)
        WHEN ''R'' THEN ''Tiered'' 
        WHEN ''G'' THEN ''Graduated'' 
        WHEN ''T'' THEN ''Texas City/Cnty Max'' 
        ELSE DECODE(COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE), ''DELETED'', NULL, ''Basic'') 
        END AS "TIER TYPE", 
      R.START_DATE_O "OLD START DATE", 
      COALESCE(R.START_DATE,RE.START_DATE) "START DATE", 
      R.END_DATE_O "OLD END DATE", 
      COALESCE(R.END_DATE,RE.END_DATE) "END DATE", 
      R.IS_LOCAL_O "OLD CASCADING", 
      COALESCE(R.IS_LOCAL,RE.IS_LOCAL) "CASCADING",
      R.UNIT_OF_MEASURE_CODE_O "OLD UNIT OF MEASURE", 
      COALESCE(R.UNIT_OF_MEASURE_CODE,RE.UNIT_OF_MEASURE_CODE) "UNIT OF MEASURE",
      CO.NAME "OLD CURRENCY", 
      C.NAME "CURRENCY", 
      CASE R.SPLIT_AMOUNT_TYPE_O 
        WHEN ''P'' THEN ''Invoice Amount By Rule'' 
        WHEN ''L'' THEN ''Line Amount'' 
        WHEN ''I'' THEN ''Invoice Amount'' 
        WHEN ''T'' THEN ''Item Amount'' 
        WHEN ''Q'' THEN ''Quantity'' 
        END AS "OLD TIER AMOUNT TYPE", 
      CASE COALESCE(R.SPLIT_AMOUNT_TYPE,RE.SPLIT_AMOUNT_TYPE)
        WHEN ''P'' THEN ''Invoice Amount By Rule'' 
        WHEN ''L'' THEN ''Line Amount'' 
        WHEN ''I'' THEN ''Invoice Amount'' 
        WHEN ''T'' THEN ''Item Amount'' 
        WHEN ''Q'' THEN ''Quantity'' 
        END AS "TIER AMOUNT TYPE", 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE coalesce(RT.AMOUNT_LOW_O,RTE.AMOUNT_LOW)
        END AS "OLD AMOUNT LOW", 
      COALESCE(RT.AMOUNT_LOW, RTE.AMOUNT_LOW) "AMOUNT LOW", --Prefer audited change over existing value 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RT.AMOUNT_HIGH_O,RTE.AMOUNT_HIGH)
        END AS "OLD AMOUNT HIGH", 
      coalesce(RT.AMOUNT_HIGH, RTE.AMOUNT_HIGH) "AMOUNT HIGH",
      CASE COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE)
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RT.RATE_O, RTE.RATE) 
        END AS "OLD TIERED RATE",
      coalesce(RT.RATE, RTE.RATE) "TIERED RATE", 
      case COALESCE(R.CHANGE_TYPE,RT.CHANGE_TYPE) 
        WHEN ''CREATED'' THEN NULL --IF CREATED THEN OLD AMOUNT IS NULL 
        ELSE COALESCE(RT.RATE_CODE_O, RTE.RATE_CODE)
        END AS "OLD REFERENCED RATE CODE", 
      COALESCE(RT.RATE_CODE, RTE.RATE_CODE) "REFERENCED RATE CODE" 
      FROM '||v_schema1_name||'.A_RATES R 
      JOIN '||v_schema1_name||'.TB_AUTHORITIES A ON (A.AUTHORITY_ID = COALESCE(R.AUTHORITY_ID,R.AUTHORITY_ID_O)) 
      JOIN '||v_schema1_name||'.TB_MERCHANTS M ON (M.MERCHANT_ID = A.MERCHANT_ID) 
      FULL outer JOIN '||v_schema1_name||'.A_RATE_TIERS RT ON (COALESCE(RT.RATE_ID,RT.RATE_ID_O) = COALESCE(R.RATE_ID,R.RATE_ID_O) AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'') --IF CREATED THEN PREFER R AND RTE AND IF IT IS NOT ONLY A RATE CHANGE
      LEFT join '||v_schema1_name||'.TB_RATE_TIERS RTE ON (RTE.RATE_ID = COALESCE(R.RATE_ID,R.RATE_ID_O) AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''-UPDATED'') --IF IT IS ONLY A RATE TIER CHANGE DON''T GO FIND THESE TIERS
      LEFT JOIN '||v_schema1_name||'.TB_RATES RE ON (RE.RATE_ID = COALESCE(RT.RATE_ID,RT.RATE_ID_O) AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'') 
      LEFT JOIN '||v_schema1_name||'.TB_AUTHORITIES AE ON (AE.AUTHORITY_ID = RE.AUTHORITY_ID AND RT.CHANGE_TYPE != ''CREATED'' AND (R.CHANGE_TYPE||''-''||RT.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema1_name||'.TB_CURRENCIES C ON (C.CURRENCY_ID = COALESCE(R.CURRENCY_ID,RE.CURRENCY_ID)) 
      LEFT JOIN '||v_schema1_name||'.TB_CURRENCIES CO ON (CO.CURRENCY_ID = R.CURRENCY_ID_O) 
      WHERE COALESCE(R.CHANGE_DATE, RT.CHANGE_DATE) > '''||v_change_date_after||'''
      AND COALESCE(R.CHANGE_DATE, RT.CHANGE_DATE) < '''||v_change_date_before||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
  )
ORDER BY 2,
  4,8,20,26');
      DBMS_OUTPUT.PUT_LINE('RATES COMPLETE');
    end_worksheet;
    start_worksheet('PRODUCTS');
    run_query('
    (
    SELECT ''Change only in '||v_system1_name||''' "CHANGE LOCATION", PC.CHANGE_TYPE "OPERATION TYPE",      PGO.NAME "OLD PRODUCT GROUP",      PG.NAME "PRODUCT GROUP",
      PC.NAME_O "OLD PRODUCT",      PC.NAME "PRODUCT",      PC.PRODCODE_O "OLD COMMODITY CODE",      PC.PRODCODE AS "COMMODITY CODE",      PC.DESCRIPTION_O "OLD DESCRIPTION",
      PC.DESCRIPTION AS "DESCRIPTION"
      FROM '||v_schema1_name||'.A_PRODUCT_CATEGORIES PC
      LEFT JOIN '||v_schema1_name||'.TB_PRODUCT_GROUPS PG on PG.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID
      LEFT JOIN '||v_schema1_name||'.tB_PRODUCT_GROUPS PGO ON PGO.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID_O
      join '||v_schema1_name||'.TB_MERCHANTS M ON coalesce(PC.MERCHANT_ID,PC.MERCHANT_ID_O) = M.MERCHANT_ID
      WHERE PC.CHANGE_DATE > '''||v_change_date_after||'''
      AND PC.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      MINUS
       SELECT ''Change only in '||v_system1_name||''' "CHANGE LOCATION", PC.CHANGE_TYPE "OPERATION TYPE",      PGO.NAME "OLD PRODUCT GROUP",      PG.NAME "PRODUCT GROUP",
      PC.NAME_O "OLD PRODUCT",      PC.NAME "PRODUCT",      PC.PRODCODE_O "OLD COMMODITY CODE",      PC.PRODCODE AS "COMMODITY CODE",      PC.DESCRIPTION_O "OLD DESCRIPTION",
      PC.DESCRIPTION AS "DESCRIPTION"
      FROM '||v_schema2_name||'.A_PRODUCT_CATEGORIES PC
      LEFT JOIN '||v_schema2_name||'.TB_PRODUCT_GROUPS PG on PG.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID
      LEFT JOIN '||v_schema2_name||'.tB_PRODUCT_GROUPS PGO ON PGO.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID_O
      join '||v_schema2_name||'.TB_MERCHANTS M ON coalesce(PC.MERCHANT_ID,PC.MERCHANT_ID_O) = M.MERCHANT_ID
      WHERE PC.CHANGE_DATE > '''||v_change_date_after2||'''
      AND PC.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      )
      UNION ALL
      (
       SELECT ''Change only in '||v_system2_name||''' "CHANGE LOCATION", PC.CHANGE_TYPE "OPERATION TYPE",      PGO.NAME "OLD PRODUCT GROUP",      PG.NAME "PRODUCT GROUP",
      PC.NAME_O "OLD PRODUCT",      PC.NAME "PRODUCT",      PC.PRODCODE_O "OLD COMMODITY CODE",      PC.PRODCODE AS "COMMODITY CODE",      PC.DESCRIPTION_O "OLD DESCRIPTION",
      PC.DESCRIPTION AS "DESCRIPTION"
      FROM '||v_schema2_name||'.A_PRODUCT_CATEGORIES PC
      LEFT JOIN '||v_schema2_name||'.TB_PRODUCT_GROUPS PG on PG.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID
      LEFT JOIN '||v_schema2_name||'.tB_PRODUCT_GROUPS PGO ON PGO.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID_O
      join '||v_schema2_name||'.TB_MERCHANTS M ON coalesce(PC.MERCHANT_ID,PC.MERCHANT_ID_O) = M.MERCHANT_ID
      WHERE PC.CHANGE_DATE > '''||v_change_date_after2||'''
      AND PC.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      MINUS
      SELECT ''Change only in '||v_system2_name||''' "CHANGE LOCATION", PC.CHANGE_TYPE "OPERATION TYPE",      PGO.NAME "OLD PRODUCT GROUP",      PG.NAME "PRODUCT GROUP",
      PC.NAME_O "OLD PRODUCT",      PC.NAME "PRODUCT",      PC.PRODCODE_O "OLD COMMODITY CODE",      PC.PRODCODE AS "COMMODITY CODE",      PC.DESCRIPTION_O "OLD DESCRIPTION",
      PC.DESCRIPTION AS "DESCRIPTION"
      FROM '||v_schema1_name||'.A_PRODUCT_CATEGORIES PC
      LEFT JOIN '||v_schema1_name||'.TB_PRODUCT_GROUPS PG on PG.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID
      LEFT JOIN '||v_schema1_name||'.tB_PRODUCT_GROUPS PGO ON PGO.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID_O
      join '||v_schema1_name||'.TB_MERCHANTS M ON coalesce(PC.MERCHANT_ID,PC.MERCHANT_ID_O) = M.MERCHANT_ID
      WHERE PC.CHANGE_DATE > '''||v_change_date_after||'''
      AND PC.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      )
      ORDER BY 2, 5, 9');
      DBMS_OUTPUT.PUT_LINE('PRODUCTS COMPLETE');
    end_worksheet;
    start_worksheet('RULES');
    run_query('
    (
    SELECT ''Change only in '||v_system1_name||''' "CHANGE LOCATION", COALESCE(RU.CHANGE_TYPE, RQ.CHANGE_TYPE) "OPERATION TYPE",      
      COALESCE(A.NAME,AE.NAME) "AUTHORITY NAME",
      RU.RULE_ORDER_O "OLD RULE ORDER",
      COALESCE(RU.RULE_ORDER,RUE.RULE_ORDER) "RULE ORDER",
      PCO.NAME "OLD PRODUCT NAME",
      PC.NAME "PRODUCT NAME",
      PCO.PRODCODE "OLD COMMODITY CODE",
      PC.PRODCODE "COMMODITY CODE",
      PGO.NAME "OLD PRODUCT GROUP",
      PG.NAME "PRODUCT GROUP",
      RU.INVOICE_DESCRIPTION_O "OLD INVOICE DESCRIPTION",
      COALESCE(RU.INVOICE_DESCRIPTION,RUE.INVOICE_DESCRIPTION) "INVOICE DESCRIPTION",
      RU.CODE_O "OLD TAX CODE",
      COALESCE(RU.CODE,RUE.CODE) "TAX CODE",
      RU.RATE_CODE_O "OLD RATE CODE",
      COALESCE(RU.RATE_CODE,RUE.RATE_CODE) "RATE CODE",
      RU.EXEMPT_O "OLD EXEMPT",
      COALESCE(RU.EXEMPT,RUE.EXEMPT) "EXEMPT",
      CASE RU.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE NVL(RU.NO_TAX_O,''N'') END AS "OLD NO TAX",
      NVL(COALESCE(RU.NO_TAX,RUE.NO_TAX),''N'') "NO TAX",
      RU.BASIS_PERCENT_O "OLD BASIS PERCENT",
      COALESCE(RU.BASIS_PERCENT,RUE.BASIS_PERCENT) "BASIS_PERCENT",
      RU.IS_LOCAL_O "OLD CASCADING",
      COALESCE(RU.IS_LOCAL,RUE.IS_LOCAL) "CASCADING",
      RU.TAX_TYPE_O "OLD TAX TYPE",
      COALESCE(RU.TAX_TYPE,RUE.TAX_TYPE) "TAX TYPE",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''TBI_CALC_METH'' AND CODE = TO_CHAR(RU.CALCULATION_METHOD_O) ) "OLD CALC METHOD",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''TBI_CALC_METH'' AND CODE = TO_CHAR(COALESCE(RU.CALCULATION_METHOD,RUE.CALCULATION_METHOD)) ) "CALC METHOD",
      RU.INPUT_RECOVERY_AMOUNT_O "OLD INPUT RECOVERY AMOUNT",
      COALESCE(RU.INPUT_RECOVERY_AMOUNT, RUE.INPUT_RECOVERY_AMOUNT) "INPUT RECOVERY AMOUNT",
      RU.INPUT_RECOVERY_PERCENT_O "OLD INPUT RECOVERY PERCENT",
      COALESCE(RU.INPUT_RECOVERY_PERCENT,RUE.INPUT_RECOVERY_PERCENT) "INPUT RECOVERY PERCENT",
      RU.START_DATE_O "OLD START DATE",
      COALESCE(RU.START_DATE,RUE.START_DATE) "START DATE",
      RU.END_DATE_O "OLD END DATE",
      COALESCE(RU.END_DATE,RUE.END_DATE) "END DATE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) END AS "OLD QUALIFIER TYPE",
      COALESCE(RQ.RULE_QUALIFIER_TYPE, RQE.RULE_QUALIFIER_TYPE) "QUALIFIER TYPE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.ELEMENT_O,RQE.ELEMENT) END AS "OLD QUALIFIER ELEMENT",
      COALESCE(RQ.ELEMENT, RQE.ELEMENT) "QUALIFIER ELEMENT",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.OPERATOR_O,RQE.OPERATOR) END AS "OLD QUALIFIER OPERATOR",
      COALESCE(RQ.OPERATOR, RQE.OPERATOR) "QUALIFIER OPERATOR",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.VALUE_O,RQE.VALUE) END AS  "OLD QUALIFIER VALUE",
      COALESCE(RQ.VALUE,RQE.VALUE) "QUALIFIER VALUE",
      RL.NAME "REFERENCE_LIST",
      RA.NAME "REFERENCED_AUTHORITY",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.START_DATE_O,RQE.START_DATE) END AS  "OLD QUALIFIER START DATE",
      COALESCE(RQ.START_DATE,RQE.START_DATE) "QUALIFIER START DATE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.END_DATE_O,RQE.END_DATE) END AS  "OLD QUALIFIER END DATE",
      COALESCE(RQ.END_DATE,RQE.END_DATE) "QUALIFIER END DATE"
      FROM '||v_schema1_name||'.A_RULES RU
      JOIN '||v_schema1_name||'.TB_MERCHANTS M ON (coalesce(RU.MERCHANT_ID,RU.MERCHANT_ID_O) = M.MERCHANT_ID)
      JOIN '||v_schema1_name||'.TB_AUTHORITIES A ON (COALESCE(RU.AUTHORITY_ID,RU.AUTHORITY_ID_O) = A.AUTHORITY_ID)
      FULL OUTER JOIN '||v_schema1_name||'.A_RULE_QUALIFIERS RQ ON (COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) = COALESCE(RU.RULE_ID,RU.RULE_ID_O) AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')--PREFER RQE ON CREATED
      LEFT JOIN '||v_schema1_name||'.TB_RULE_QUALIFIERS RQE ON (RQE.RULE_ID = COALESCE(RU.RULE_ID,RU.RULE_ID_O) AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''-UPDATED'')
      LEFT JOIN '||v_schema1_name||'.TB_RULES RUE ON (RUE.RULE_ID = COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema1_name||'.TB_AUTHORITIES AE ON (RUE.AUTHORITY_ID = AE.AUTHORITY_ID AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema1_name||'.TB_PRODUCT_CATEGORIES PC ON (PC.PRODUCT_CATEGORY_ID = COALESCE(RU.PRODUCT_CATEGORY_ID,RUE.PRODUCT_CATEGORY_ID))
      LEFT JOIN '||v_schema1_name||'.TB_PRODUCT_GROUPS PG ON (PG.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID)
      LEFT JOIN '||v_schema1_name||'.TB_PRODUCT_CATEGORIES PCO ON (PCO.PRODUCT_CATEGORY_ID = RU.PRODUCT_CATEGORY_ID_O)
      LEFT JOIN '||v_schema1_name||'.TB_PRODUCT_GROUPS PGO ON (PGO.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID)
      LEFT JOIN '||v_schema1_name||'.TB_REFERENCE_LISTS RL ON (RL.REFERENCE_LIST_ID = CASE WHEN COALESCE(RQ.RULE_QUALIFIER_TYPE, RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) = ''LIST'' THEN COALESCE(RQ.REFERENCE_LIST_ID, RQ.REFERENCE_LIST_ID_O, RQE.REFERENCE_LIST_ID) ELSE NULL END)
      LEFT JOIN '||v_schema1_name||'.TB_AUTHORITIES RA ON (RL.REFERENCE_LIST_ID = CASE WHEN COALESCE(RQ.RULE_QUALIFIER_TYPE, RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) = ''AUTHORITY'' THEN COALESCE(RQ.AUTHORITY_ID, RQ.AUTHORITY_ID_O, RQE.AUTHORITY_ID) ELSE NULL END)
      WHERE COALESCE(RU.CHANGE_DATE,RQ.CHANGE_DATE) > '''||v_change_date_after||'''
      AND COALESCE(RU.CHANGE_DATE,RQ.CHANGE_DATE) < '''||v_change_date_before||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
    MINUS
      SELECT ''Change only in '||v_system1_name||''' "CHANGE LOCATION", COALESCE(RU.CHANGE_TYPE, RQ.CHANGE_TYPE) "OPERATION TYPE",      
      COALESCE(A.NAME,AE.NAME) "AUTHORITY NAME",
      RU.RULE_ORDER_O "OLD RULE ORDER",
      COALESCE(RU.RULE_ORDER,RUE.RULE_ORDER) "RULE ORDER",
      PCO.NAME "OLD PRODUCT NAME",
      PC.NAME "PRODUCT NAME",
      PCO.PRODCODE "OLD COMMODITY CODE",
      PC.PRODCODE "COMMODITY CODE",
      PGO.NAME "OLD PRODUCT GROUP",
      PG.NAME "PRODUCT GROUP",
      RU.INVOICE_DESCRIPTION_O "OLD INVOICE DESCRIPTION",
      COALESCE(RU.INVOICE_DESCRIPTION,RUE.INVOICE_DESCRIPTION) "INVOICE DESCRIPTION",
      RU.CODE_O "OLD TAX CODE",
      COALESCE(RU.CODE,RUE.CODE) "TAX CODE",
      RU.RATE_CODE_O "OLD RATE CODE",
      COALESCE(RU.RATE_CODE,RUE.RATE_CODE) "RATE CODE",
      RU.EXEMPT_O "OLD EXEMPT",
      COALESCE(RU.EXEMPT,RUE.EXEMPT) "EXEMPT",
      CASE RU.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE NVL(RU.NO_TAX_O,''N'') END AS "OLD NO TAX",
      NVL(COALESCE(RU.NO_TAX,RUE.NO_TAX),''N'') "NO TAX",
      RU.BASIS_PERCENT_O "OLD BASIS PERCENT",
      COALESCE(RU.BASIS_PERCENT,RUE.BASIS_PERCENT) "BASIS_PERCENT",
      RU.IS_LOCAL_O "OLD CASCADING",
      COALESCE(RU.IS_LOCAL,RUE.IS_LOCAL) "CASCADING",
      RU.TAX_TYPE_O "OLD TAX TYPE",
      COALESCE(RU.TAX_TYPE,RUE.TAX_TYPE) "TAX TYPE",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''TBI_CALC_METH'' AND CODE = TO_CHAR(RU.CALCULATION_METHOD_O) ) "OLD CALC METHOD",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''TBI_CALC_METH'' AND CODE = TO_CHAR(COALESCE(RU.CALCULATION_METHOD,RUE.CALCULATION_METHOD)) ) "CALC METHOD",
      RU.INPUT_RECOVERY_AMOUNT_O "OLD INPUT RECOVERY AMOUNT",
      COALESCE(RU.INPUT_RECOVERY_AMOUNT, RUE.INPUT_RECOVERY_AMOUNT) "INPUT RECOVERY AMOUNT",
      RU.INPUT_RECOVERY_PERCENT_O "OLD INPUT RECOVERY PERCENT",
      COALESCE(RU.INPUT_RECOVERY_PERCENT,RUE.INPUT_RECOVERY_PERCENT) "INPUT RECOVERY PERCENT",
      RU.START_DATE_O "OLD START DATE",
      COALESCE(RU.START_DATE,RUE.START_DATE) "START DATE",
      RU.END_DATE_O "OLD END DATE",
      COALESCE(RU.END_DATE,RUE.END_DATE) "END DATE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) END AS "OLD QUALIFIER TYPE",
      COALESCE(RQ.RULE_QUALIFIER_TYPE, RQE.RULE_QUALIFIER_TYPE) "QUALIFIER TYPE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.ELEMENT_O,RQE.ELEMENT) END AS "OLD QUALIFIER ELEMENT",
      COALESCE(RQ.ELEMENT, RQE.ELEMENT) "QUALIFIER ELEMENT",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.OPERATOR_O,RQE.OPERATOR) END AS "OLD QUALIFIER OPERATOR",
      COALESCE(RQ.OPERATOR, RQE.OPERATOR) "QUALIFIER OPERATOR",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.VALUE_O,RQE.VALUE) END AS  "OLD QUALIFIER VALUE",
      COALESCE(RQ.VALUE,RQE.VALUE) "QUALIFIER VALUE",
      RL.NAME "REFERENCE_LIST",
      RA.NAME "REFERENCED_AUTHORITY",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.START_DATE_O,RQE.START_DATE) END AS  "OLD QUALIFIER START DATE",
      COALESCE(RQ.START_DATE,RQE.START_DATE) "QUALIFIER START DATE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.END_DATE_O,RQE.END_DATE) END AS  "OLD QUALIFIER END DATE",
      COALESCE(RQ.END_DATE,RQE.END_DATE) "QUALIFIER END DATE"
      FROM '||v_schema2_name||'.A_RULES RU
      JOIN '||v_schema2_name||'.TB_MERCHANTS M ON (coalesce(RU.MERCHANT_ID,RU.MERCHANT_ID_O) = M.MERCHANT_ID)
      JOIN '||v_schema2_name||'.TB_AUTHORITIES A ON (COALESCE(RU.AUTHORITY_ID,RU.AUTHORITY_ID_O) = A.AUTHORITY_ID)
      FULL OUTER JOIN '||v_schema2_name||'.A_RULE_QUALIFIERS RQ ON (COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) = COALESCE(RU.RULE_ID,RU.RULE_ID_O) AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')--PREFER RQE ON CREATED
      LEFT JOIN '||v_schema2_name||'.TB_RULE_QUALIFIERS RQE ON (RQE.RULE_ID = COALESCE(RU.RULE_ID,RU.RULE_ID_O) AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''-UPDATED'')
      LEFT JOIN '||v_schema2_name||'.TB_RULES RUE ON (RUE.RULE_ID = COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema2_name||'.TB_AUTHORITIES AE ON (RUE.AUTHORITY_ID = AE.AUTHORITY_ID AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema2_name||'.TB_PRODUCT_CATEGORIES PC ON (PC.PRODUCT_CATEGORY_ID = COALESCE(RU.PRODUCT_CATEGORY_ID,RUE.PRODUCT_CATEGORY_ID))
      LEFT JOIN '||v_schema2_name||'.TB_PRODUCT_GROUPS PG ON (PG.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID)
      LEFT JOIN '||v_schema2_name||'.TB_PRODUCT_CATEGORIES PCO ON (PCO.PRODUCT_CATEGORY_ID = RU.PRODUCT_CATEGORY_ID_O)
      LEFT JOIN '||v_schema2_name||'.TB_PRODUCT_GROUPS PGO ON (PGO.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID)
      LEFT JOIN '||v_schema2_name||'.TB_REFERENCE_LISTS RL ON (RL.REFERENCE_LIST_ID = CASE WHEN COALESCE(RQ.RULE_QUALIFIER_TYPE, RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) = ''LIST'' THEN COALESCE(RQ.REFERENCE_LIST_ID, RQ.REFERENCE_LIST_ID_O, RQE.REFERENCE_LIST_ID) ELSE NULL END)
      LEFT JOIN '||v_schema2_name||'.TB_AUTHORITIES RA ON (RL.REFERENCE_LIST_ID = CASE WHEN COALESCE(RQ.RULE_QUALIFIER_TYPE, RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) = ''AUTHORITY'' THEN COALESCE(RQ.AUTHORITY_ID, RQ.AUTHORITY_ID_O, RQE.AUTHORITY_ID) ELSE NULL END)
      WHERE COALESCE(RU.CHANGE_DATE,RQ.CHANGE_DATE) > '''||v_change_date_after2||'''
      AND COALESCE(RU.CHANGE_DATE,RQ.CHANGE_DATE) < '''||v_change_date_before2||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%'' 
      )
  UNION ALL
      (
      SELECT ''Change only in '||v_system2_name||''' "CHANGE LOCATION", COALESCE(RU.CHANGE_TYPE, RQ.CHANGE_TYPE) "OPERATION TYPE",      
      COALESCE(A.NAME,AE.NAME) "AUTHORITY NAME",
      RU.RULE_ORDER_O "OLD RULE ORDER",
      COALESCE(RU.RULE_ORDER,RUE.RULE_ORDER) "RULE ORDER",
      PCO.NAME "OLD PRODUCT NAME",
      PC.NAME "PRODUCT NAME",
      PCO.PRODCODE "OLD COMMODITY CODE",
      PC.PRODCODE "COMMODITY CODE",
      PGO.NAME "OLD PRODUCT GROUP",
      PG.NAME "PRODUCT GROUP",
      RU.INVOICE_DESCRIPTION_O "OLD INVOICE DESCRIPTION",
      COALESCE(RU.INVOICE_DESCRIPTION,RUE.INVOICE_DESCRIPTION) "INVOICE DESCRIPTION",
      RU.CODE_O "OLD TAX CODE",
      COALESCE(RU.CODE,RUE.CODE) "TAX CODE",
      RU.RATE_CODE_O "OLD RATE CODE",
      COALESCE(RU.RATE_CODE,RUE.RATE_CODE) "RATE CODE",
      RU.EXEMPT_O "OLD EXEMPT",
      COALESCE(RU.EXEMPT,RUE.EXEMPT) "EXEMPT",
      CASE RU.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE NVL(RU.NO_TAX_O,''N'') END AS "OLD NO TAX",
      NVL(COALESCE(RU.NO_TAX,RUE.NO_TAX),''N'') "NO TAX",
      RU.BASIS_PERCENT_O "OLD BASIS PERCENT",
      COALESCE(RU.BASIS_PERCENT,RUE.BASIS_PERCENT) "BASIS_PERCENT",
      RU.IS_LOCAL_O "OLD CASCADING",
      COALESCE(RU.IS_LOCAL,RUE.IS_LOCAL) "CASCADING",
      RU.TAX_TYPE_O "OLD TAX TYPE",
      COALESCE(RU.TAX_TYPE,RUE.TAX_TYPE) "TAX TYPE",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''TBI_CALC_METH'' AND CODE = TO_CHAR(RU.CALCULATION_METHOD_O) ) "OLD CALC METHOD",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''TBI_CALC_METH'' AND CODE = TO_CHAR(COALESCE(RU.CALCULATION_METHOD,RUE.CALCULATION_METHOD)) ) "CALC METHOD",
      RU.INPUT_RECOVERY_AMOUNT_O "OLD INPUT RECOVERY AMOUNT",
      COALESCE(RU.INPUT_RECOVERY_AMOUNT, RUE.INPUT_RECOVERY_AMOUNT) "INPUT RECOVERY AMOUNT",
      RU.INPUT_RECOVERY_PERCENT_O "OLD INPUT RECOVERY PERCENT",
      COALESCE(RU.INPUT_RECOVERY_PERCENT,RUE.INPUT_RECOVERY_PERCENT) "INPUT RECOVERY PERCENT",
      RU.START_DATE_O "OLD START DATE",
      COALESCE(RU.START_DATE,RUE.START_DATE) "START DATE",
      RU.END_DATE_O "OLD END DATE",
      COALESCE(RU.END_DATE,RUE.END_DATE) "END DATE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) END AS "OLD QUALIFIER TYPE",
      COALESCE(RQ.RULE_QUALIFIER_TYPE, RQE.RULE_QUALIFIER_TYPE) "QUALIFIER TYPE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.ELEMENT_O,RQE.ELEMENT) END AS "OLD QUALIFIER ELEMENT",
      COALESCE(RQ.ELEMENT, RQE.ELEMENT) "QUALIFIER ELEMENT",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.OPERATOR_O,RQE.OPERATOR) END AS "OLD QUALIFIER OPERATOR",
      COALESCE(RQ.OPERATOR, RQE.ELEMENT) "QUALIFIER OPERATOR",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.VALUE_O,RQE.VALUE) END AS  "OLD QUALIFIER VALUE",
      COALESCE(RQ.VALUE,RQE.VALUE) "QUALIFIER VALUE",
      RL.NAME "REFERENCE_LIST",
      RA.NAME "REFERENCED_AUTHORITY",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.START_DATE_O,RQE.START_DATE) END AS  "OLD QUALIFIER START DATE",
      COALESCE(RQ.START_DATE,RQE.START_DATE) "QUALIFIER START DATE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.END_DATE_O,RQE.END_DATE) END AS  "OLD QUALIFIER END DATE",
      COALESCE(RQ.END_DATE,RQE.START_DATE) "QUALIFIER END DATE"
      FROM '||v_schema2_name||'.A_RULES RU
      JOIN '||v_schema2_name||'.TB_MERCHANTS M ON (coalesce(RU.MERCHANT_ID,RU.MERCHANT_ID_O) = M.MERCHANT_ID)
      JOIN '||v_schema2_name||'.TB_AUTHORITIES A ON (COALESCE(RU.AUTHORITY_ID,RU.AUTHORITY_ID_O) = A.AUTHORITY_ID)
      FULL OUTER JOIN '||v_schema2_name||'.A_RULE_QUALIFIERS RQ ON (COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) = COALESCE(RU.RULE_ID,RU.RULE_ID_O) AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')--PREFER RQE ON CREATED
      LEFT JOIN '||v_schema2_name||'.TB_RULE_QUALIFIERS RQE ON (RQE.RULE_ID = COALESCE(RU.RULE_ID,RU.RULE_ID_O) AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''-UPDATED'')
      LEFT JOIN '||v_schema2_name||'.TB_RULES RUE ON (RUE.RULE_ID = COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema2_name||'.TB_AUTHORITIES AE ON (RUE.AUTHORITY_ID = AE.AUTHORITY_ID AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema2_name||'.TB_PRODUCT_CATEGORIES PC ON (PC.PRODUCT_CATEGORY_ID = COALESCE(RU.PRODUCT_CATEGORY_ID,RUE.PRODUCT_CATEGORY_ID))
      LEFT JOIN '||v_schema2_name||'.TB_PRODUCT_GROUPS PG ON (PG.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID)
      LEFT JOIN '||v_schema2_name||'.TB_PRODUCT_CATEGORIES PCO ON (PCO.PRODUCT_CATEGORY_ID = RU.PRODUCT_CATEGORY_ID_O)
      LEFT JOIN '||v_schema2_name||'.TB_PRODUCT_GROUPS PGO ON (PGO.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID)
      LEFT JOIN '||v_schema2_name||'.TB_REFERENCE_LISTS RL ON (RL.REFERENCE_LIST_ID = CASE WHEN COALESCE(RQ.RULE_QUALIFIER_TYPE, RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) = ''LIST'' THEN COALESCE(RQ.REFERENCE_LIST_ID, RQ.REFERENCE_LIST_ID_O, RQE.REFERENCE_LIST_ID) ELSE NULL END)
      LEFT JOIN '||v_schema2_name||'.TB_AUTHORITIES RA ON (RL.REFERENCE_LIST_ID = CASE WHEN COALESCE(RQ.RULE_QUALIFIER_TYPE, RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) = ''AUTHORITY'' THEN COALESCE(RQ.AUTHORITY_ID, RQ.AUTHORITY_ID_O, RQE.AUTHORITY_ID) ELSE NULL END)
      WHERE COALESCE(RU.CHANGE_DATE,RQ.CHANGE_DATE) > '''||v_change_date_after2||'''
      AND COALESCE(RU.CHANGE_DATE,RQ.CHANGE_DATE) < '''||v_change_date_before2||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''    
 MINUS
      SELECT ''Change only in '||v_system2_name||''' "CHANGE LOCATION", COALESCE(RU.CHANGE_TYPE, RQ.CHANGE_TYPE) "OPERATION TYPE",      
      COALESCE(A.NAME,AE.NAME) "AUTHORITY NAME",
      RU.RULE_ORDER_O "OLD RULE ORDER",
      COALESCE(RU.RULE_ORDER,RUE.RULE_ORDER) "RULE ORDER",
      PCO.NAME "OLD PRODUCT NAME",
      PC.NAME "PRODUCT NAME",
      PCO.PRODCODE "OLD COMMODITY CODE",
      PC.PRODCODE "COMMODITY CODE",
      PGO.NAME "OLD PRODUCT GROUP",
      PG.NAME "PRODUCT GROUP",
      RU.INVOICE_DESCRIPTION_O "OLD INVOICE DESCRIPTION",
      COALESCE(RU.INVOICE_DESCRIPTION,RUE.INVOICE_DESCRIPTION) "INVOICE DESCRIPTION",
      RU.CODE_O "OLD TAX CODE",
      COALESCE(RU.CODE,RUE.CODE) "TAX CODE",
      RU.RATE_CODE_O "OLD RATE CODE",
      COALESCE(RU.RATE_CODE,RUE.RATE_CODE) "RATE CODE",
      RU.EXEMPT_O "OLD EXEMPT",
      COALESCE(RU.EXEMPT,RUE.EXEMPT) "EXEMPT",
      CASE RU.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE NVL(RU.NO_TAX_O,''N'') END AS "OLD NO TAX",
      NVL(COALESCE(RU.NO_TAX,RUE.NO_TAX),''N'') "NO TAX",
      RU.BASIS_PERCENT_O "OLD BASIS PERCENT",
      COALESCE(RU.BASIS_PERCENT,RUE.BASIS_PERCENT) "BASIS_PERCENT",
      RU.IS_LOCAL_O "OLD CASCADING",
      COALESCE(RU.IS_LOCAL,RUE.IS_LOCAL) "CASCADING",
      RU.TAX_TYPE_O "OLD TAX TYPE",
      COALESCE(RU.TAX_TYPE,RUE.TAX_TYPE) "TAX TYPE",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''TBI_CALC_METH'' AND CODE = TO_CHAR(RU.CALCULATION_METHOD_O) ) "OLD CALC METHOD",
      (SELECT DESCRIPTION FROM TB_LOOKUPS WHERE CODE_GROUP = ''TBI_CALC_METH'' AND CODE = TO_CHAR(COALESCE(RU.CALCULATION_METHOD,RUE.CALCULATION_METHOD)) ) "CALC METHOD",
      RU.INPUT_RECOVERY_AMOUNT_O "OLD INPUT RECOVERY AMOUNT",
      COALESCE(RU.INPUT_RECOVERY_AMOUNT, RUE.INPUT_RECOVERY_AMOUNT) "INPUT RECOVERY AMOUNT",
      RU.INPUT_RECOVERY_PERCENT_O "OLD INPUT RECOVERY PERCENT",
      COALESCE(RU.INPUT_RECOVERY_PERCENT,RUE.INPUT_RECOVERY_PERCENT) "INPUT RECOVERY PERCENT",
      RU.START_DATE_O "OLD START DATE",
      COALESCE(RU.START_DATE,RUE.START_DATE) "START DATE",
      RU.END_DATE_O "OLD END DATE",
      COALESCE(RU.END_DATE,RUE.END_DATE) "END DATE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) END AS "OLD QUALIFIER TYPE",
      COALESCE(RQ.RULE_QUALIFIER_TYPE, RQE.RULE_QUALIFIER_TYPE) "QUALIFIER TYPE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.ELEMENT_O,RQE.ELEMENT) END AS "OLD QUALIFIER ELEMENT",
      COALESCE(RQ.ELEMENT, RQE.ELEMENT) "QUALIFIER ELEMENT",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.OPERATOR_O,RQE.OPERATOR) END AS "OLD QUALIFIER OPERATOR",
      COALESCE(RQ.OPERATOR, RQE.ELEMENT) "QUALIFIER OPERATOR",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.VALUE_O,RQE.VALUE) END AS  "OLD QUALIFIER VALUE",
      COALESCE(RQ.VALUE,RQE.VALUE) "QUALIFIER VALUE",
      RL.NAME "REFERENCE_LIST",
      RA.NAME "REFERENCED_AUTHORITY",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.START_DATE_O,RQE.START_DATE) END AS  "OLD QUALIFIER START DATE",
      COALESCE(RQ.START_DATE,RQE.START_DATE) "QUALIFIER START DATE",
      CASE RQ.CHANGE_TYPE
        WHEN ''CREATED'' THEN NULL
        ELSE COALESCE(RQ.END_DATE_O,RQE.END_DATE) END AS  "OLD QUALIFIER END DATE",
      COALESCE(RQ.END_DATE,RQE.START_DATE) "QUALIFIER END DATE"
      FROM '||v_schema1_name||'.A_RULES RU
      JOIN '||v_schema1_name||'.TB_MERCHANTS M ON (coalesce(RU.MERCHANT_ID,RU.MERCHANT_ID_O) = M.MERCHANT_ID)
      JOIN '||v_schema1_name||'.TB_AUTHORITIES A ON (COALESCE(RU.AUTHORITY_ID,RU.AUTHORITY_ID_O) = A.AUTHORITY_ID)
      FULL OUTER JOIN '||v_schema1_name||'.A_RULE_QUALIFIERS RQ ON (COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) = COALESCE(RU.RULE_ID,RU.RULE_ID_O) AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')--PREFER RQE ON CREATED
      LEFT JOIN '||v_schema1_name||'.TB_RULE_QUALIFIERS RQE ON (RQE.RULE_ID = COALESCE(RU.RULE_ID,RU.RULE_ID_O) AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''-UPDATED'')
      LEFT JOIN '||v_schema1_name||'.TB_RULES RUE ON (RUE.RULE_ID = COALESCE(RQ.RULE_ID,RQ.RULE_ID_O) AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema1_name||'.TB_AUTHORITIES AE ON (RUE.AUTHORITY_ID = AE.AUTHORITY_ID AND RQ.CHANGE_TYPE != ''CREATED'' AND (RU.CHANGE_TYPE||''-''||RQ.CHANGE_TYPE)!=''UPDATED-'')
      LEFT JOIN '||v_schema1_name||'.TB_PRODUCT_CATEGORIES PC ON (PC.PRODUCT_CATEGORY_ID = COALESCE(RU.PRODUCT_CATEGORY_ID,RUE.PRODUCT_CATEGORY_ID))
      LEFT JOIN '||v_schema1_name||'.TB_PRODUCT_GROUPS PG ON (PG.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID)
      LEFT JOIN '||v_schema1_name||'.TB_PRODUCT_CATEGORIES PCO ON (PCO.PRODUCT_CATEGORY_ID = RU.PRODUCT_CATEGORY_ID_O)
      LEFT JOIN '||v_schema1_name||'.TB_PRODUCT_GROUPS PGO ON (PGO.PRODUCT_GROUP_ID = PC.PRODUCT_GROUP_ID)
      LEFT JOIN '||v_schema1_name||'.TB_REFERENCE_LISTS RL ON (RL.REFERENCE_LIST_ID = CASE WHEN COALESCE(RQ.RULE_QUALIFIER_TYPE, RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) = ''LIST'' THEN COALESCE(RQ.REFERENCE_LIST_ID, RQ.REFERENCE_LIST_ID_O, RQE.REFERENCE_LIST_ID) ELSE NULL END)
      LEFT JOIN '||v_schema1_name||'.TB_AUTHORITIES RA ON (RL.REFERENCE_LIST_ID = CASE WHEN COALESCE(RQ.RULE_QUALIFIER_TYPE, RQ.RULE_QUALIFIER_TYPE_O,RQE.RULE_QUALIFIER_TYPE) = ''AUTHORITY'' THEN COALESCE(RQ.AUTHORITY_ID, RQ.AUTHORITY_ID_O, RQE.AUTHORITY_ID) ELSE NULL END)
      WHERE COALESCE(RU.CHANGE_DATE,RQ.CHANGE_DATE) > '''||v_change_date_after||'''
      AND COALESCE(RU.CHANGE_DATE,RQ.CHANGE_DATE) < '''||v_change_date_before||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%'' 
      )
      ORDER BY 2, 4,10, 6, 28');
      DBMS_OUTPUT.PUT_LINE('RULES COMPLETE');
    end_worksheet;
    start_worksheet('AUTHORITY MAPPINGS');
    run_query('
    (
    SELECT ''Change only in '||v_system1_name||''' "CHANGE LOCATION", ZA.CHANGE_TYPE "OPERATION TYPE",      ZP2.NAME "GREAT GRAND PARENT ZONE NAME", ZP1.NAME "GRANDPARENT ZONE NAME", ZP.NAME "PARENT ZONE NAME",  ZL.NAME "ZONE LEVEL",     ZO.NAME "OLD ZONE NAME",      Z.NAME "ZONE NAME",      AO.NAME "OLD AUTHORITY MAPPED",
      A.NAME "AUTHORITY MAPPED"
      FROM '||v_schema1_name||'.A_ZONE_AUTHORITIES ZA, '||v_schema1_name||'.TB_AUTHORITIES A, '||v_schema1_name||'.TB_AUTHORITIES AO, '||v_schema1_name||'.TB_ZONES Z, '||v_schema1_name||'.TB_ZONES ZO, '||v_schema1_name||'.TB_MERCHANTS M, '||v_schema1_name||'.TB_ZONES ZP, '||v_schema1_name||'.TB_ZONES ZP1, '||v_schema1_name||'.TB_ZONES ZP2, '||v_schema1_name||'.TB_ZONE_LEVELS ZL
      WHERE M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND ZA.CHANGE_DATE > '''||v_change_date_after||'''
      AND ZA.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.MERCHANT_ID = COALESCE(A.MERCHANT_ID,AO.MERCHANT_ID)
      AND ZA.AUTHORITY_ID_O = AO.AUTHORITY_ID(+)
      AND ZA.AUTHORITY_ID = A.AUTHORITY_ID(+)
      AND ZA.ZONE_ID = Z.ZONE_ID(+)
      AND ZA.ZONE_ID_O = ZO.ZONE_ID(+)
      AND ZP.ZONE_ID = COALESCE(Z.PARENT_ZONE_ID, ZO.PARENT_ZONE_ID)
      AND ZL.ZONE_LEVEL_ID = COALESCE(Z.ZONE_LEVEL_ID, ZO.ZONE_LEVEL_ID)
      AND NVL(ZP.PARENT_ZONE_ID, -1) = ZP1.ZONE_ID
      AND NVL(ZP1.PARENT_ZONE_ID, -1) = ZP2.ZONE_ID
      MINUS
    SELECT ''Change only in '||v_system1_name||''' "CHANGE LOCATION", ZA.CHANGE_TYPE "OPERATION TYPE",      ZP2.NAME "GREAT GRAND PARENT ZONE NAME", ZP1.NAME "GRANDPARENT ZONE NAME", ZP.NAME "PARENT ZONE NAME",  ZL.NAME "ZONE LEVEL",  ZO.NAME "OLD ZONE NAME",      Z.NAME "ZONE NAME",      AO.NAME "OLD AUTHORITY MAPPED",
      A.NAME "AUTHORITY MAPPED"
      FROM '||v_schema2_name||'.A_ZONE_AUTHORITIES ZA, '||v_schema2_name||'.TB_AUTHORITIES A, '||v_schema2_name||'.TB_AUTHORITIES AO, '||v_schema2_name||'.TB_ZONES Z, '||v_schema2_name||'.TB_ZONES ZO, '||v_schema2_name||'.TB_MERCHANTS M, '||v_schema2_name||'.TB_ZONES ZP, '||v_schema2_name||'.TB_ZONES ZP1, '||v_schema2_name||'.TB_ZONES ZP2, '||v_schema2_name||'.TB_ZONE_LEVELS ZL
      WHERE M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND ZA.CHANGE_DATE > '''||v_change_date_after2||'''
      AND ZA.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.MERCHANT_ID = COALESCE(A.MERCHANT_ID,AO.MERCHANT_ID)
      AND ZA.AUTHORITY_ID_O = AO.AUTHORITY_ID(+)
      AND ZA.AUTHORITY_ID = A.AUTHORITY_ID(+)
      AND ZA.ZONE_ID = Z.ZONE_ID(+)
      AND ZA.ZONE_ID_O = ZO.ZONE_ID(+)
      AND ZP.ZONE_ID = COALESCE(Z.PARENT_ZONE_ID, ZO.PARENT_ZONE_ID)
            AND ZL.ZONE_LEVEL_ID = COALESCE(Z.ZONE_LEVEL_ID, ZO.ZONE_LEVEL_ID)
      AND NVL(ZP.PARENT_ZONE_ID, -1) = ZP1.ZONE_ID
      AND NVL(ZP1.PARENT_ZONE_ID, -1) = ZP2.ZONE_ID      
      )
      UNION ALL
      (
    SELECT ''Change only in '||v_system2_name||''' "CHANGE LOCATION", ZA.CHANGE_TYPE "OPERATION TYPE",      ZP2.NAME "GREAT GRAND PARENT ZONE NAME", ZP1.NAME "GRANDPARENT ZONE NAME", ZP.NAME "PARENT ZONE NAME",  ZL.NAME "ZONE LEVEL", ZO.NAME "OLD ZONE NAME",      Z.NAME "ZONE NAME",      AO.NAME "OLD AUTHORITY MAPPED",
      A.NAME "AUTHORITY MAPPED"
      FROM '||v_schema2_name||'.A_ZONE_AUTHORITIES ZA, '||v_schema2_name||'.TB_AUTHORITIES A, '||v_schema2_name||'.TB_AUTHORITIES AO, '||v_schema2_name||'.TB_ZONES Z, '||v_schema2_name||'.TB_ZONES ZO, '||v_schema2_name||'.TB_MERCHANTS M, '||v_schema2_name||'.TB_ZONES ZP, '||v_schema2_name||'.TB_ZONES ZP1, '||v_schema2_name||'.TB_ZONES ZP2, '||v_schema2_name||'.TB_ZONE_LEVELS ZL
      WHERE M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND ZA.CHANGE_DATE > '''||v_change_date_after2||'''
      AND ZA.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.MERCHANT_ID = COALESCE(A.MERCHANT_ID,AO.MERCHANT_ID)
      AND ZA.AUTHORITY_ID_O = AO.AUTHORITY_ID(+)
      AND ZA.AUTHORITY_ID = A.AUTHORITY_ID(+)
      AND ZA.ZONE_ID = Z.ZONE_ID(+)
      AND ZA.ZONE_ID_O = ZO.ZONE_ID(+)
      AND ZP.ZONE_ID = COALESCE(Z.PARENT_ZONE_ID, ZO.PARENT_ZONE_ID)
            AND ZL.ZONE_LEVEL_ID = COALESCE(Z.ZONE_LEVEL_ID, ZO.ZONE_LEVEL_ID)
      AND NVL(ZP.PARENT_ZONE_ID, -1) = ZP1.ZONE_ID
      AND NVL(ZP1.PARENT_ZONE_ID, -1) = ZP2.ZONE_ID   
      MINUS
     SELECT ''Change only in '||v_system2_name||''' "CHANGE LOCATION", ZA.CHANGE_TYPE "OPERATION TYPE",      ZP2.NAME "GREAT GRAND PARENT ZONE NAME", ZP1.NAME "GRANDPARENT ZONE NAME", ZP.NAME "PARENT ZONE NAME",  ZL.NAME "ZONE LEVEL",  ZO.NAME "OLD ZONE NAME",      Z.NAME "ZONE NAME",      AO.NAME "OLD AUTHORITY MAPPED",
      A.NAME "AUTHORITY MAPPED"
      FROM '||v_schema1_name||'.A_ZONE_AUTHORITIES ZA, '||v_schema1_name||'.TB_AUTHORITIES A, '||v_schema1_name||'.TB_AUTHORITIES AO, '||v_schema1_name||'.TB_ZONES Z, '||v_schema1_name||'.TB_ZONES ZO, '||v_schema1_name||'.TB_MERCHANTS M, '||v_schema1_name||'.TB_ZONES ZP, '||v_schema1_name||'.TB_ZONES ZP1, '||v_schema1_name||'.TB_ZONES ZP2, '||v_schema1_name||'.TB_ZONE_LEVELS ZL
      WHERE M.NAME LIKE ''Sabrix ''||'''||v_content_type||'''||''%''
      AND ZA.CHANGE_DATE > '''||v_change_date_after||'''
      AND ZA.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.MERCHANT_ID = COALESCE(A.MERCHANT_ID,AO.MERCHANT_ID)
      AND ZA.AUTHORITY_ID_O = AO.AUTHORITY_ID(+)
      AND ZA.AUTHORITY_ID = A.AUTHORITY_ID(+)
      AND ZA.ZONE_ID = Z.ZONE_ID(+)
      AND ZA.ZONE_ID_O = ZO.ZONE_ID(+)
      AND ZP.ZONE_ID = COALESCE(Z.PARENT_ZONE_ID, ZO.PARENT_ZONE_ID)
      AND ZL.ZONE_LEVEL_ID = COALESCE(Z.ZONE_LEVEL_ID, ZO.ZONE_LEVEL_ID)
      AND NVL(ZP.PARENT_ZONE_ID, -1) = ZP1.ZONE_ID
      AND NVL(ZP1.PARENT_ZONE_ID, -1) = ZP2.ZONE_ID     
      )
      order by 2, 4, 5,6,9');
      DBMS_OUTPUT.PUT_LINE('AUTHORITY MAPPINGS COMPLETE');
    end_worksheet;
    start_worksheet('ZONES');
    run_query('
    (
    SELECT ''Change only in '||v_system1_name||''' "CHANGE LOCATION", Z.CHANGE_TYPE "OPERATION TYPE",      ZP2.NAME "GREAT GRANDPARENT",      ZP1.NAME "GRANDPARENT",
      ZP.NAME "PARENT",      Z.NAME_O "OLD NAME",      Z.NAME "NAME",      ZLO.NAME "OLD LEVEL",      ZL.NAME "LEVEL",
      Z.EU_ZONE_AS_OF_DATE_O "OLD EU ZONE AS OF",      Z.EU_ZONE_AS_OF_DATE "EU ZONE AS OF",      Z.CODE_2CHAR_O "OLD SHORT CODE",      Z.CODE_2CHAR "SHORT CODE",      Z.CODE_3CHAR_O "OLD 3-CHAR CODE",
      Z.CODE_3CHAR "3-CHAR CODE",      Z.CODE_ISO_O "OLD ISO CODE",      Z.CODE_ISO "ISO CODE",      Z.CODE_FIPS_O "OLD FIPS CODE",      Z.CODE_FIPS "FIPS CODE",
      Z.REVERSE_FLAG_O "OLD BOTTOM UP PROCESSING",      Z.REVERSE_FLAG "BOTTOM UP PROCESSING",      Z.TERMINATOR_FLAG_O "OLD TERMINATES PROCESSING",      Z.TERMINATOR_FLAG "TERMINATES PROCESSING"
      FROM '||v_schema1_name||'.A_ZONES Z
      LEFT OUTER JOIN '||v_schema1_name||'.TB_ZONES ZP ON (COALESCE(Z.PARENT_ZONE_ID,Z.PARENT_ZONE_ID_O) = ZP.ZONE_ID)
      LEFT OUTER JOIN '||v_schema1_name||'.TB_ZONE_LEVELS ZL ON ( Z.ZONE_LEVEL_ID = ZL.ZONE_LEVEL_ID)
      JOIN '||v_schema1_name||'.TB_MERCHANTS M ON (M.MERCHANT_ID = COALESCE(Z.MERCHANT_ID,Z.MERCHANT_ID_O))
      LEFT OUTER JOIN '||v_schema1_name||'.TB_ZONE_LEVELS ZLO ON(ZLO.ZONE_LEVEL_ID = Z.ZONE_LEVEL_ID_O)
      LEFT OUTER JOIN '||v_schema1_name||'.TB_ZONES ZP1 ON (ZP1.ZONE_ID = ZP.PARENT_ZONE_ID )
      LEFT OUTER JOIN '||v_schema1_name||'.TB_ZONES ZP2 ON (ZP2.ZONE_ID = ZP1.PARENT_ZONE_ID )
      WHERE Z.CHANGE_DATE > '''||v_change_date_after||'''
      AND Z.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type|| '''||''%''
      AND Z.ZONE_LEVEL_ID > -7
      MINUS
    SELECT ''Change only in '||v_system1_name||''' "CHANGE LOCATION", Z.CHANGE_TYPE "OPERATION TYPE",      ZP2.NAME "GREAT GRANDPARENT",      ZP1.NAME "GRANDPARENT",
      ZP.NAME "PARENT",      Z.NAME_O "OLD NAME",      Z.NAME "NAME",      ZLO.NAME "OLD LEVEL",      ZL.NAME "LEVEL",
      Z.EU_ZONE_AS_OF_DATE_O "OLD EU ZONE AS OF",      Z.EU_ZONE_AS_OF_DATE "EU ZONE AS OF",      Z.CODE_2CHAR_O "OLD SHORT CODE",      Z.CODE_2CHAR "SHORT CODE",      Z.CODE_3CHAR_O "OLD 3-CHAR CODE",
      Z.CODE_3CHAR "3-CHAR CODE",      Z.CODE_ISO_O "OLD ISO CODE",      Z.CODE_ISO "ISO CODE",      Z.CODE_FIPS_O "OLD FIPS CODE",      Z.CODE_FIPS "FIPS CODE",
      Z.REVERSE_FLAG_O "OLD BOTTOM UP PROCESSING",      Z.REVERSE_FLAG "BOTTOM UP PROCESSING",      Z.TERMINATOR_FLAG_O "OLD TERMINATES PROCESSING",      Z.TERMINATOR_FLAG "TERMINATES PROCESSING"
      FROM '||v_schema2_name||'.A_ZONES Z
      LEFT OUTER JOIN '||v_schema2_name||'.TB_ZONES ZP ON (COALESCE(Z.PARENT_ZONE_ID,Z.PARENT_ZONE_ID_O) = ZP.ZONE_ID)
      LEFT OUTER JOIN '||v_schema2_name||'.TB_ZONE_LEVELS ZL ON ( Z.ZONE_LEVEL_ID = ZL.ZONE_LEVEL_ID)
      JOIN '||v_schema2_name||'.TB_MERCHANTS M ON (M.MERCHANT_ID = COALESCE(Z.MERCHANT_ID,Z.MERCHANT_ID_O))
      LEFT OUTER JOIN '||v_schema2_name||'.TB_ZONE_LEVELS ZLO ON(ZLO.ZONE_LEVEL_ID = Z.ZONE_LEVEL_ID_O)
      LEFT OUTER JOIN '||v_schema2_name||'.TB_ZONES ZP1 ON (ZP1.ZONE_ID = ZP.PARENT_ZONE_ID )
      LEFT OUTER JOIN '||v_schema2_name||'.TB_ZONES ZP2 ON (ZP2.ZONE_ID = ZP1.PARENT_ZONE_ID )
      WHERE Z.CHANGE_DATE > '''||v_change_date_after2||'''
      AND Z.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type|| '''||''%''
      AND Z.ZONE_LEVEL_ID > -7      
      )
      UNION ALL
      (
    SELECT ''Change only in '||v_system2_name||''' "CHANGE LOCATION", Z.CHANGE_TYPE "OPERATION TYPE",      ZP2.NAME "GREAT GRANDPARENT",      ZP1.NAME "GRANDPARENT",
      ZP.NAME "PARENT",      Z.NAME_O "OLD NAME",      Z.NAME "NAME",      ZLO.NAME "OLD LEVEL",      ZL.NAME "LEVEL",
      Z.EU_ZONE_AS_OF_DATE_O "OLD EU ZONE AS OF",      Z.EU_ZONE_AS_OF_DATE "EU ZONE AS OF",      Z.CODE_2CHAR_O "OLD SHORT CODE",      Z.CODE_2CHAR "SHORT CODE",      Z.CODE_3CHAR_O "OLD 3-CHAR CODE",
      Z.CODE_3CHAR "3-CHAR CODE",      Z.CODE_ISO_O "OLD ISO CODE",      Z.CODE_ISO "ISO CODE",      Z.CODE_FIPS_O "OLD FIPS CODE",      Z.CODE_FIPS "FIPS CODE",
      Z.REVERSE_FLAG_O "OLD BOTTOM UP PROCESSING",      Z.REVERSE_FLAG "BOTTOM UP PROCESSING",      Z.TERMINATOR_FLAG_O "OLD TERMINATES PROCESSING",      Z.TERMINATOR_FLAG "TERMINATES PROCESSING"
      FROM '||v_schema2_name||'.A_ZONES Z
      LEFT OUTER JOIN '||v_schema2_name||'.TB_ZONES ZP ON (COALESCE(Z.PARENT_ZONE_ID,Z.PARENT_ZONE_ID_O) = ZP.ZONE_ID)
      LEFT OUTER JOIN '||v_schema2_name||'.TB_ZONE_LEVELS ZL ON ( Z.ZONE_LEVEL_ID = ZL.ZONE_LEVEL_ID)
      JOIN '||v_schema2_name||'.TB_MERCHANTS M ON (M.MERCHANT_ID = COALESCE(Z.MERCHANT_ID,Z.MERCHANT_ID_O))
      LEFT OUTER JOIN '||v_schema2_name||'.TB_ZONE_LEVELS ZLO ON(ZLO.ZONE_LEVEL_ID = Z.ZONE_LEVEL_ID_O)
      LEFT OUTER JOIN '||v_schema2_name||'.TB_ZONES ZP1 ON (ZP1.ZONE_ID = ZP.PARENT_ZONE_ID )
      LEFT OUTER JOIN '||v_schema2_name||'.TB_ZONES ZP2 ON (ZP2.ZONE_ID = ZP1.PARENT_ZONE_ID )
      WHERE Z.CHANGE_DATE > '''||v_change_date_after2||'''
      AND Z.CHANGE_DATE < '''||v_change_date_before2||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type|| '''||''%''
      AND Z.ZONE_LEVEL_ID > -7   
      MINUS
      SELECT ''Change only in '||v_system2_name||''' "CHANGE LOCATION", Z.CHANGE_TYPE "OPERATION TYPE",      ZP2.NAME "GREAT GRANDPARENT",      ZP1.NAME "GRANDPARENT",
      ZP.NAME "PARENT",      Z.NAME_O "OLD NAME",      Z.NAME "NAME",      ZLO.NAME "OLD LEVEL",      ZL.NAME "LEVEL",
      Z.EU_ZONE_AS_OF_DATE_O "OLD EU ZONE AS OF",      Z.EU_ZONE_AS_OF_DATE "EU ZONE AS OF",      Z.CODE_2CHAR_O "OLD SHORT CODE",      Z.CODE_2CHAR "SHORT CODE",      Z.CODE_3CHAR_O "OLD 3-CHAR CODE",
      Z.CODE_3CHAR "3-CHAR CODE",      Z.CODE_ISO_O "OLD ISO CODE",      Z.CODE_ISO "ISO CODE",      Z.CODE_FIPS_O "OLD FIPS CODE",      Z.CODE_FIPS "FIPS CODE",
      Z.REVERSE_FLAG_O "OLD BOTTOM UP PROCESSING",      Z.REVERSE_FLAG "BOTTOM UP PROCESSING",      Z.TERMINATOR_FLAG_O "OLD TERMINATES PROCESSING",      Z.TERMINATOR_FLAG "TERMINATES PROCESSING"
      FROM '||v_schema1_name||'.A_ZONES Z
      LEFT OUTER JOIN '||v_schema1_name||'.TB_ZONES ZP ON (COALESCE(Z.PARENT_ZONE_ID,Z.PARENT_ZONE_ID_O) = ZP.ZONE_ID)
      LEFT OUTER JOIN '||v_schema1_name||'.TB_ZONE_LEVELS ZL ON ( Z.ZONE_LEVEL_ID = ZL.ZONE_LEVEL_ID)
      JOIN '||v_schema1_name||'.TB_MERCHANTS M ON (M.MERCHANT_ID = COALESCE(Z.MERCHANT_ID,Z.MERCHANT_ID_O))
      LEFT OUTER JOIN '||v_schema1_name||'.TB_ZONE_LEVELS ZLO ON(ZLO.ZONE_LEVEL_ID = Z.ZONE_LEVEL_ID_O)
      LEFT OUTER JOIN '||v_schema1_name||'.TB_ZONES ZP1 ON (ZP1.ZONE_ID = ZP.PARENT_ZONE_ID )
      LEFT OUTER JOIN '||v_schema1_name||'.TB_ZONES ZP2 ON (ZP2.ZONE_ID = ZP1.PARENT_ZONE_ID )
      WHERE Z.CHANGE_DATE > '''||v_change_date_after||'''
      AND Z.CHANGE_DATE < '''||v_change_date_before||'''
      AND M.NAME LIKE ''Sabrix ''||'''||v_content_type|| '''||''%''
      AND Z.ZONE_LEVEL_ID > -7
      )
      ORDER BY 2, 4, 5, 6, 8');
      DBMS_OUTPUT.PUT_LINE('ZONES COMPLETE');
    end_worksheet;
    end_workbook;
    if length(io_buffer)>0 then
          DBMS_LOB.writeappend(v_clob, LENGTH(io_buffer), io_buffer);
    end if;
  END create_full_change_clob;

END CHANGE_RECORD_COMPARE_DATE;
/