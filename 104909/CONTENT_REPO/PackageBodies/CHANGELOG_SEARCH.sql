CREATE OR REPLACE PACKAGE BODY content_repo."CHANGELOG_SEARCH"
IS
    -- MODIFICATION HISTORY
    -- Person      Date     Comments
    -- ---------   ------   -------------------------------------------
    -- tnn                  official name search juris, tax, taxability, geography
    -- tnn                  rid column for change log as part of result
    -- tnn         12/15    sVerifiedBy
    -- tnn         12/4/14  srchI changed to varchar2(512) in fnAndIs()
    -- tnn         12/4/14  srchI VARCHAR2(256) in fnIsTextEntered()
    -- tnn                  bckp LISTAGG(ast.id||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''') WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
    -- tnn         02/09/14 jurisidiction_nkid added

    -- Generic sql set
    sq_Entity CLOB  := ' ';  -- final query
    sq_Main CLOB    := ' ';  -- Entity main columns and join
    sq_Reason CLOB  := ' LEFT JOIN change_reasons cr ON (cr.id = clo.reason_id) ';
    sq_Data CLOB    := ' ';
    sq_whr CLOB     := ' ';
    sq_UserSet CLOB := ' JOIN content_repo.users usr ON (usr.id = clo.entered_by) ';
    grpBy_Default CLOB :=' GROUP BY
                           clo.id
                          ,clo.entered_by
                          ,usr.firstname || '' '' || usr.lastname
                          ,clo.status_modified_date
                          ,clo.entered_date
                          ,cr.reason
                          ,ast.id
                          ,etm.ui_alias|| '': ''||q.qr';

    colDelim VARCHAR2(2) := ', ';

    q_rollup_qry VARCHAR2(1024) := 'SELECT DISTINCT LISTAGG(CHANGE_LOGID,'','') within group (order by COL_JNAME) over (partition by COL_JNAME) CHANGE_LOGID,
LISTAGG(COL_RID,'','') within group (order by COL_RID) over (partition by COL_JNAME) COL_RID,
COL_PUBLISHED,
COL_MODIFIED,
COL_BY,
LISTAGG(COL_REASON,'','') within group (order by COL_RID) over (partition by COL_JNAME) COL_REASON,
COL_VERIFIED_BY,
COL_JNAME,
sum(COL_DOCUMENTS) over(partition by COL_JNAME) COL_DOCUMENTS,
REFERENCE_CODE,
count(distinct CHANGE_LOGID) over (partition by COL_JNAME)||'' detail records'' table_name,
SECTION_ID,
COL_NKID,
LISTAGG(COL_DOC_ID_LIST,'','') within group (order by COL_JNAME) over (partition by COL_JNAME) COL_DOC_ID_LIST,
jurisdiction_rid
,juris_tax_imposition_rid
,jurisdiction_nkid from(';


    FUNCTION fnConcatColNames(searchVar IN VARCHAR2) RETURN VARCHAR2 IS
        srchI varchar2(512);
    BEGIN
        IF LENGTH(searchVar)>0 THEN
            srchI := REGEXP_REPLACE(searchVar,'\,','||');
        ELSE
            srchI:=' ';
        END IF;
        RETURN srchI;
    END;


    --fn "is text entered?" Single set of text as a LIKE.
    FUNCTION fnIsTextEntered(searchText IN VARCHAR2, dataCol IN VARCHAR2) RETURN VARCHAR2 IS
        srchI VARCHAR2(256);
    BEGIN
        IF length(searchText)>0 THEN
            srchI := ' AND UPPER('||dataCol||') LIKE UPPER('''||searchText||'%'')';
        ELSE -- explicit YES or NO is it blank
            srchI :=' ';
        END IF;
        RETURN srchI;
    END;


    --fn "include IN or just one value"
    FUNCTION fnAndIs(searchVar IN VARCHAR2, dataCol IN varchar2) RETURN VARCHAR2 IS
        srchI varchar2(512);
    BEGIN
        IF LENGTH(searchVar)>0 THEN
            IF REGEXP_COUNT(searchVar, ',', 1, 'i') > 0 THEN
                srchI := ' AND '||dataCol||' IN('||searchVar||')';
            ELSE
            -- cluge
            -- 12/18 now allowing usr id < 0 to be used
            --IF TO_NUMBER(searchVar)>0 THEN
                srchI :=' AND '||dataCol||' = '||searchVar;
            --ELSE
            --  srchI :=' AND '||dataCol||' is null ';
            --END IF;
            END IF;
       ELSE
            srchI:=' ';
       END IF;
       RETURN srchI;
    END;


    FUNCTION fnAndIs2(searchVar IN VARCHAR2, dataCol IN varchar2) RETURN VARCHAR2 IS
        srchI varchar2(512);
    BEGIN
        IF LENGTH(searchVar)>0 THEN
            IF REGEXP_COUNT(searchVar, ',', 1, 'i') > 0 THEN
                srchI := ' ('||dataCol||' IN('||searchVar||')';
            ELSE
                srchI :=' ('||dataCol||' = '||searchVar;
            END IF;
       ELSE
            srchI:=' ';
       END IF;
       RETURN srchI;
    END;


    /*
    FUNCTION fnAndIs2(searchVar IN VARCHAR2, dataCol IN varchar2) RETURN VARCHAR2 IS
        srchI varchar2(512);
    BEGIN
        IF LENGTH(searchVar)>0 THEN
            IF REGEXP_COUNT(searchVar, ',', 1, 'i') > 0 THEN
                srchI := ' AND ('||dataCol||' IN('||searchVar||')';
            ELSE
                srchI :=' AND ('||dataCol||' = '||searchVar;
            END IF;
       ELSE
            srchI:=' ';
       END IF;
       RETURN srchI;
    END;
    */


    FUNCTION returnWhere(sdAfter IN VARCHAR2 DEFAULT NULL, sdBefore IN VARCHAR2 DEFAULT NULL) RETURN VARCHAR2 IS
        stw varchar2(256);
    BEGIN
        IF sdAfter IS NOT NULL THEN
            stw := stw || ' AND clo.entered_date >=to_date('''||sdAfter||''',''DD-MON-YYYY'')';
        END IF;

        IF sdBefore IS NOT NULL THEN
            stw := stw || ' AND clo.entered_date <=TO_DATE('''||sdBefore||''',''DD-MON-YYYY'')';
        END IF;
        RETURN stw;
    END;




    -- ADMINISTRATOR --
    PROCEDURE getAdmin(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
                       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
                       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
                       nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
                       p_ref OUT SYS_REFCURSOR)
    IS
        --
        -- Admin {var}
        --
        --v_tab tableSearchAdmin := tableSearchAdmin(); -- for pipeline {disregard}
        sq_Doc CLOB  := ' LEFT JOIN admin_chg_cits cc ON (cc.admin_chg_log_id = clo.id)
                          LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                          LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
        sq_Verif CLOB:= ' LEFT JOIN admin_chg_vlds cva ON (cva.admin_chg_log_id = clo.id)
                          LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
        sq_Tags CLOB := ' LEFT OUTER JOIN administrator_tags admtgs on (admtgs.ref_nkid = ar.nkid)
                          LEFT OUTER JOIN Tags tgs ON (tgs.id = admtgs.tag_id) ';
        addgroupStmt CLOB := ',clo.status
                              ,clo.rid
                              ,ar.name
                              ,ar.nkid
                              ,atc.id
                              ,cva.assigned_user_id
                              ,tgs.name, tgs.id ';
        form_columns CLOB;
    BEGIN
        --                   ,''Documents(''||count(distinct ci.attachment_id)||'')'' COL_DOCUMENTS
        -- COL_JNAME -> COL_ADMINISTRATOR
        --                  , wm_concat(distinct atc.id) COL_DOC_ID_LIST    -- Changed to SYS_XMLAGG - CRAPP-2516

        sq_Main := 'SELECT DISTINCT
                           clo.id change_logId
                           , clo.rid COL_RID
                           , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                  WHEN clo.status = 1 THEN ''Locked''
                                  ELSE ''Pending''
                             END COL_PUBLISHED
                           , clo.entered_date COL_MODIFIED
                           , usr.firstname || '' '' ||usr.lastname COL_BY
                           , cr.reason COL_REASON
                           , regexp_replace(LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                     WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
                                     ,''([^,]+)(, \1)+'', ''\1'')
                                     AS COL_VERIFIED_BY
                           , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                           , ar.name COL_ADMINISTRATOR
                           , '' '' REFERENCE_CODE
                           , etm.ui_alias||'': ''||q.qr table_name
                           --, etm.ui_alias table_name
                           , ar.nkid COL_NKID
                           , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                           , '' '' jurisdiction_rid
                           , '' '' juris_tax_imposition_rid
                           , '' '' jurisdiction_nkid
                           , regexp_replace(LISTAGG(tgs.name, '','') WITHIN GROUP (ORDER BY tgs.id) over (PARTITION BY clo.id)
                           ,''([^,]+)(,\1)+'', ''\1'')
                           TAG_NAME
                    FROM admin_chg_logs clo
                         JOIN entity_table_map etm on (etm.table_name = clo.table_name AND etm.logical_entity = ''Administrator'')
                         JOIN admin_qr q on (q.table_name = etm.table_name and q.ref_id = clo.primary_key)
                         -- Entity

                         -- Adminstrators base data
                         JOIN administrator_revisions rv ON (rv.id = clo.rid)
                         JOIN administrators ar ON (rv.nkid = ar.nkid AND rev_join(ar.rid,rv.id,ar.next_rid) = 1) ';

        --> Verified By
        sVerifiedBy:=fnAndIs2(searchVar=>verifiedBy, dataCol=>'assigned_user_id');

        if length(sVerifiedBy)>1 then
            DBMS_OUTPUT.Put_Line( 'Verified By:'||sVerifiedBy );
            --sVerifiedBy := concat(sVerifiedBy,' or cva.assigned_user_id = any(cva.assigned_user_id) )');
            --sVerifiedBy := fnAndIs(searchVar=>verifiedBy, dataCol=>'cva.assigned_user_id');
            sVerifiedBy := concat(sVerifiedBy,' ');
        end if;

        --> Modified by
        sectionModifyBy := fnAndIs(searchVar=>search_ModifBy, dataCol=>'clo.entered_by');

        --> Reason
        sectionReason := fnAndIs(searchVar=>search_Reason, dataCol=>'cr.id');

        -- if performance hit; get this one later
        --> Associated Document Name
        sectionDocs := fnIsTextEntered(searchText=>search_Doc, dataCol=>'atc.display_name');

        -- reminder: display multiple
        --> Verified By
        sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');

        --> Data Range
        --sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'ar.status');
        sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'clo.status');

        --> Tags
        sectionTags := fnAndIs(searchVar=>search_Tags, dataCol=>'tgs.id');

        --> Citation ID if passed from Research Documentation
        sectionCit := fnAndIs(searchVar=>nCitationID, dataCol=>'ci.id');


        sq_whr := concat(fnConvertINtoList(search_Verif, sVerifiedBy, 1), ' WHERE 1=1');
        IF search_Verif IS NOT NULL THEN
            sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');
        END IF;

        sq_whr := sq_whr || returnWhere(sdAfter=>modifAfter, sdBefore=>modifBefore);
        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Verif || sq_Data || sq_Tags;
        sq_entity := sq_entity || sq_whr|| sectionModifyBy;
        sq_entity := sq_entity || sectionReason || sectionDocs || sectionVerif || sectionDataRange || sectionTags || sectionCit;

        -- todo: might need to check sVerifiedBy here
        select case when sectionVerif<>'' then ''
                    when sectionVerif<>'' and sVerifiedBy <> '' then 'AND '||sVerifiedBy||')'
                    else '' end
        into sVerifiedBy
        from dual;

        sq_Entity := sq_Entity|| sVerifiedBy;
        sq_Entity := sq_Entity|| grpBy_Default|| addgroupStmt;

        -- Columns for UI
        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED,
                                to_char(COL_MODIFIED,''mm/dd/yyyy HH24:mi:ss'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, COL_ADMINISTRATOR, REFERENCE_CODE,
                                table_name, 1 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
                                , TAG_NAME
                         FROM ( ';

        form_columns := form_columns || sq_entity ||') ORDER BY TO_DATE(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') DESC ';
        --form_columns := q_rollup_qry||form_columns||sq_entity||')';

        -- debug
        DBMS_OUTPUT.Put_Line( form_columns );

        OPEN p_ref FOR form_columns;
        -- if needed; use USING and replace values with :name for binding

    END getAdmin;




    -- JURISDICTION --
    PROCEDURE getJurisdiction(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
                              search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
                              modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
                              nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
                              p_ref OUT SYS_REFCURSOR, pOfficialName IN VARCHAR2 DEFAULT NULL)
    IS
        --
        -- Jurisdiction {var}
        --
        sq_Doc CLOB  := ' LEFT JOIN juris_chg_cits cc ON (cc.juris_chg_log_id = clo.id)
                          LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                          LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
        sq_Verif CLOB:= ' LEFT JOIN juris_chg_vlds cva ON (cva.juris_chg_log_id = clo.id)
                          LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
        sq_Tags CLOB := ' LEFT OUTER JOIN jurisdiction_tags admtgs on (admtgs.ref_nkid = ar.nkid)
                          LEFT OUTER JOIN
                            Tags tgs ON (tgs.id = admtgs.tag_id) ';

        addgroupStmt CLOB := ',clo.status
                              ,clo.rid
                              ,ar.official_name
                              ,ar.nkid
                              ,atc.id
                              ,q.table_name
                              ,ctf.official_name
                              ,cva.assigned_user_id
                              ,tgs.name, tgs.id ';
        form_columns CLOB;
        s_Juris CLOB;
    BEGIN
        -- 0 pending
        -- 1 locked
        -- 2 published
        -- ,''Documents(''||nvl(count(distinct ci.attachment_id),0)||'')'' COL_DOCUMENTS

        --                 , wm_concat(distinct atc.id) COL_DOC_ID_LIST     -- Changed to LISTAGG - CRAPP-2516
        --                 , etm.ui_alias||'': ''||q.qr table_name          -- Modified to include Contributes To/From Official Name - CRAPP-2516

        sq_Main := 'SELECT DISTINCT
                           clo.id change_logId
                           , clo.rid COL_RID
                           , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                  WHEN clo.status = 1 THEN ''Locked''
                                  ELSE ''Pending''
                             END COL_PUBLISHED
                           , clo.entered_date COL_MODIFIED
                           , usr.firstname ||  '' '' ||usr.lastname COL_BY
                           , cr.reason COL_REASON
                           , regexp_replace(LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                     WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
                                     ,''([^,]+)(, \1)+'', ''\1'')
                                     AS COL_VERIFIED_BY
                           , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                           , ar.official_name COL_JNAME
                           , '' '' REFERENCE_CODE
                           , CASE WHEN q.table_name LIKE ''%TAX_RELATIONSHIPS'' THEN etm.ui_alias||'': ''||q.qr||'': ''||ctf.official_name
                                  ELSE etm.ui_alias||'': ''||q.qr
                             END table_name
                           , ar.nkid COL_NKID
                           , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                           , '''' jurisdiction_rid
                           , '''' juris_tax_imposition_rid
                           , '''' jurisdiction_nkid
                           , regexp_replace(LISTAGG(tgs.name, '','') WITHIN GROUP (ORDER BY tgs.id) over (PARTITION BY clo.id)
                           ,''([^,]+)(,\1)+'', ''\1'') TAG_NAME
                    FROM juris_chg_logs clo
                         JOIN entity_table_map etm on (etm.table_name = clo.table_name)
                         JOIN juris_qr q on (q.table_name = etm.table_name and q.ref_id = clo.primary_key)
                         -- Entity
                         AND etm.logical_entity = ''Jurisdiction''
                         -- Jurisdiction base data
                         JOIN jurisdiction_revisions rv ON (rv.id = clo.rid)
                         -- Contributions To/From
                         LEFT JOIN jurisdictions ctf ON (q.ref_nkid = ctf.nkid AND ctf.next_rid IS NULL)';

        -- 1/29/2015 prep for official name field
        if pOfficialName is not null then
            s_Juris := ' JOIN jurisdictions ar ON (rv.nkid = ar.nkid
                                                   AND rev_join (ar.rid, rv.id, COALESCE (ar.next_rid, 999999999)) = 1
                                                   AND UPPER(ar.official_name) LIKE UPPER(''%'||pOfficialName||'%'') ) ';
        else
            s_Juris := ' JOIN jurisdictions ar ON (rv.nkid = ar.nkid
                                                   AND rev_join (ar.rid, rv.id, COALESCE (ar.next_rid, 999999999)) = 1) ';
        end if;

        --> Verified By
        sVerifiedBy := fnAndIs2(searchVar=>verifiedBy, dataCol=>'assigned_user_id');

        if length(sVerifiedBy)>1 then
            sVerifiedBy := concat(sVerifiedBy,' ');
        end if;

        --> Modified by
        sectionModifyBy := fnAndIs(searchVar=>search_ModifBy, dataCol=>'clo.entered_by');

        --> Reason
        sectionReason := fnAndIs(searchVar=>search_Reason, dataCol=>'cr.id');

        --> Associated Document Name
        sectionDocs := fnIsTextEntered(searchText=>search_Doc, dataCol=>'atc.display_name');

        --> Verified By
        sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');

        --> Data Range
        sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'clo.status');

        --> Tags
        sectionTags := fnAndIs(searchVar=>search_Tags, dataCol=>'tgs.id');

        --> Citation ID if passed from Research Documentation
        sectionCit := fnAndIs(searchVar=>nCitationID, dataCol=>'ci.id');

        sq_whr := concat(fnConvertINtoList(search_Verif, sVerifiedBy, 2), ' WHERE 1=1');
        IF search_Verif IS NOT NULL THEN
            sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');
        END IF;

        sq_whr := sq_whr || returnWhere(sdAfter=>modifAfter, sdBefore=>modifBefore);
        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Verif || sq_Data || s_Juris || sq_Tags;
        sq_entity := sq_entity || sq_whr|| sectionModifyBy;
        sq_entity := sq_entity || sectionReason || sectionDocs || sectionVerif || sectionDataRange || sectionTags || sectionCit;

        -- todo: might need to check sVerifiedBy here
        select case when sectionVerif<>'' then ''
                    when sectionVerif<>'' and sVerifiedBy<>'' then 'AND '||sVerifiedBy||')'
                    else '' end
        into sVerifiedBy
        from dual;

        sq_Entity := sq_Entity || sVerifiedBy;
        sq_Entity := sq_Entity || grpBy_Default || addgroupStmt;

        -- Columns for form {layout}
        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:mi:ss'') COL_MODIFIED,
                                COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME, REFERENCE_CODE, table_name,
                                2 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
                                , TAG_NAME
                         FROM ( ';
        --3/10
        form_columns := form_columns || sq_entity ||') ORDER BY TO_DATE(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') DESC ';

        -- dev debug
        dbms_output.put_line(form_columns);

        OPEN p_ref FOR form_columns;
    END getJurisdiction;





    -- ******
    -- * Tax
    -- ******
    PROCEDURE getTax(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
                     search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
                     modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
                     nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
                     p_ref OUT SYS_REFCURSOR, pOfficialName IN VARCHAR2 DEFAULT NULL)
    IS

      --
      -- Tax
      --
      sq_Doc CLOB  := ' LEFT JOIN juris_tax_chg_cits cc ON (cc.juris_tax_chg_log_id = clo.id)
                        LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                        LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
      sq_Verif CLOB:= ' LEFT JOIN juris_tax_chg_vlds cva ON (cva.juris_tax_chg_log_id = clo.id)
                        LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
      sq_Tags CLOB := ' LEFT OUTER JOIN juris_tax_imposition_tags admtgs on (admtgs.ref_nkid = ar.nkid)
                        LEFT OUTER JOIN Tags tgs ON (tgs.id = admtgs.tag_id) ';
      addgroupStmt CLOB := ',clo.status
                            ,clo.rid
                            ,jr.official_name
                            ,ar.reference_code
                            ,ar.nkid
                            ,ar.rid
                            ,jr.rid
                            ,jr.nkid
                            ,atc.id
                            ,cva.assigned_user_id
                            ,tgs.name, tgs.id ';
      form_columns CLOB;
      s_Juris clob;
    BEGIN
        -- , wm_concat(distinct atc.id) COL_DOC_ID_LIST -- Changed to LISTAGG - CRAPP-2516

        sq_Main := 'SELECT DISTINCT
                           clo.id change_logId
                           , clo.rid COL_RID
                           , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                  WHEN clo.status = 1 THEN ''Locked''
                                  ELSE ''Pending''
                             END COL_PUBLISHED
                           , clo.entered_date COL_MODIFIED
                           , usr.firstname ||  '' '' ||usr.lastname COL_BY
                           , cr.reason COL_REASON
                           , regexp_replace(LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                     WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
                                     ,''([^,]+)(, \1)+'', ''\1'')
                                     AS COL_VERIFIED_BY
                           , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                           , jr.official_name COL_JNAME
                           , ar.reference_code REFERENCE_CODE
                           , etm.ui_alias||'': ''||q.qr table_name
                           , ar.nkid COL_NKID
                           , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                           , jr.rid jurisdiction_rid
                           , clo.rid juris_tax_imposition_rid
                           , jr.nkid jurisdiction_nkid
                           , regexp_replace(LISTAGG(tgs.name, '','') WITHIN GROUP (ORDER BY tgs.id) over (PARTITION BY clo.id)
                           ,''([^,]+)(,\1)+'', ''\1'')
                           TAG_NAME
                    FROM juris_tax_chg_logs clo
                         JOIN entity_table_map etm on (etm.table_name = clo.table_name)
                         JOIN tax_qr q on (q.table_name = etm.table_name and q.ref_id = clo.primary_key)
                         -- Entity
                         AND etm.logical_entity = ''Tax''
                         JOIN jurisdiction_tax_revisions rv ON (rv.id = clo.rid)
                         JOIN juris_tax_impositions ar ON (ar.nkid = rv.nkid)';

        if pOfficialName is not null then
            s_Juris:=' JOIN jurisdictions jr ON (jr.id = ar.jurisdiction_id
                                                 AND UPPER(jr.official_name) LIKE UPPER(''%'||pOfficialName||'%'') ) ';
        else
            s_Juris:=' JOIN jurisdictions jr ON (jr.id = ar.jurisdiction_id) ';
        end if;

        -- AND rev_join(ar.rid,rv.id,ar.next_rid) = 1)
        --,ar.rid juris_tax_imposition_rid

        --> Verified By
        sVerifiedBy:=fnAndIs2(searchVar=>verifiedBy, dataCol=>'assigned_user_id');
        if length(sVerifiedBy)>1 then
            sVerifiedBy:=concat(sVerifiedBy,' ');
        end if;

        --> Modified by
        sectionModifyBy := fnAndIs(searchVar=>search_ModifBy, dataCol=>'clo.entered_by');

        --> Reason
        sectionReason := fnAndIs(searchVar=>search_Reason, dataCol=>'cr.id');

        -- if performance hit; get this one later
        --> Associated Document Name
        sectionDocs := fnIsTextEntered(searchText=>search_Doc, dataCol=>'atc.display_name');

        -- reminder: display multiple
        --> Verified By
        sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');

        --> Data Range
        --sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'ar.status');
        sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'clo.status');

        --> Tags
        sectionTags := fnAndIs(searchVar=>search_Tags, dataCol=>'tgs.id');

        --> Citation ID if passed from Research Documentation
        sectionCit := fnAndIs(searchVar=>nCitationID, dataCol=>'ci.id');

        -- Main where
        --IF search_Verif IS NOT NULL THEN
        --sq_whr :=fnConvertINtoList(search_Verif,sVerifiedBy,3);
        sq_whr := concat(fnConvertINtoList(search_Verif, sVerifiedBy, 3), ' WHERE 1=1');
        IF search_Verif IS NOT NULL THEN
            sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');
        --ELSE
        --  sq_whr :='WHERE 1=1';
        END IF;

        sq_whr := sq_whr || returnWhere(sdAfter=>modifAfter, sdBefore=>modifBefore);

        -- CONCAT {prefer || instead of nested CONCAT}
        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Verif || sq_Data || s_Juris || sq_Tags;
        sq_entity := sq_entity|| sq_whr|| sectionModifyBy;
        sq_entity := sq_entity|| sectionReason || sectionDocs || sectionVerif || sectionDataRange || sectionTags || sectionCit;

        select case when sectionVerif<>'' then ''
                    when sectionVerif<>'' and sVerifiedBy <> '' then 'AND '||sVerifiedBy||')'
                    else '' end
        into sVerifiedBy
        from dual;

        sq_Entity := sq_Entity|| sVerifiedBy;
        sq_Entity := sq_Entity|| grpBy_Default || addgroupStmt;

        -- Columns for form {layout}
        -- Either use this to select the specific columns or send back all of them to the app
        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:mi:ss'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME, REFERENCE_CODE, table_name,
                                3 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
                                , TAG_NAME
                         FROM ( ';

        form_columns := form_columns || sq_entity || ') ORDER BY TO_DATE(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') DESC ';
        --form_columns:=q_rollup_qry||form_columns||sq_entity||'))';

        -- Debug
        dbms_output.put_line(form_columns);

        OPEN p_ref FOR form_columns;
    END getTax;





    -- ******
    -- * Taxability
    -- ******
    PROCEDURE getTaxability(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
                            search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
                            modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
                            nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
                            p_ref OUT SYS_REFCURSOR, pOfficialName IN VARCHAR2 DEFAULT NULL)
    IS
      --
      -- Taxability
      --
      sq_Doc CLOB  := ' LEFT JOIN juris_tax_app_chg_cits cc ON (cc.juris_tax_app_chg_log_id = clo.id)
                        LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                        LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
      sq_Verif CLOB:= ' LEFT JOIN juris_tax_app_chg_vlds cva ON (cva.juris_tax_app_chg_log_id = clo.id)
                        LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
      sq_Tags CLOB := ' LEFT OUTER JOIN juris_tax_app_tags admtgs on (admtgs.ref_nkid = ar.nkid)
                        LEFT OUTER JOIN Tags tgs ON (tgs.id = admtgs.tag_id) ';
      addgroupStmt CLOB := ',clo.status
                            ,clo.rid
                            ,jr.official_name
                            ,jr.rid
                            ,jr.nkid
                            ,ar.rid
                            ,com.NAME
                            ,ar.nkid
                            ,atc.id
                            ,etm.ui_alias
                            ,cva.assigned_user_id
                            ,tgs.name, tgs.id ';

                            --,ar.reference_code    -- Replaced with 'com.NAME' - CRAPP-2516

      form_columns CLOB;
      s_Juris      CLOB;
    BEGIN
        --                  ,LISTAGG(ast.id||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''') WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
        --                  , wm_concat(distinct atc.id) COL_DOC_ID_LIST    -- Changed to LISTAGG - CRAPP-2516
        --                  , ar.reference_code REFERENCE_CODE              -- Changed to com.NAME - CRAPP-2516
        --                  JOIN juris_tax_applicabilities                  -- Changed to JURIS_TAX_APPLICABILITIES - CRAPP-2516

        sq_Main := 'SELECT DISTINCT
                           clo.id change_logId
                           , clo.rid COL_RID
                           , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                  WHEN clo.status = 1 THEN ''Locked''
                                  ELSE ''Pending'' END COL_PUBLISHED
                           , clo.entered_date COL_MODIFIED
                           , usr.firstname ||  '' '' ||usr.lastname COL_BY
                           , cr.reason COL_REASON
                           , regexp_replace(LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                     WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
                                     ,''([^,]+)(, \1)+'', ''\1'')
                                     AS COL_VERIFIED_BY
                           , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                           , jr.official_name COL_JNAME
                           , CASE WHEN com.NAME IS NOT NULL THEN com.NAME
                                  ELSE ''All Commodities Apply''
                             END REFERENCE_CODE

                           --, etm.ui_alias||'': ''||q.qr table_name

                           , CASE WHEN etm.ui_alias = ''Taxability Details'' THEN
                                        CASE WHEN com.NAME IS NOT NULL THEN etm.ui_alias||'': ''||com.NAME
                                             ELSE etm.ui_alias||'': All Commodities Apply''
                                        END
                                  ELSE etm.ui_alias||'': ''||q.qr
                             END table_name

                           , ar.nkid COL_NKID
                           , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                           , jr.rid jurisdiction_rid
                           , clo.rid juris_tax_imposition_rid
                           , jr.nkid jurisdiction_nkid
                           , regexp_replace(LISTAGG(tgs.name, '','') WITHIN GROUP (ORDER BY tgs.id) over (PARTITION BY clo.id)
                           ,''([^,]+)(,\1)+'', ''\1'')
                           TAG_NAME
                    FROM juris_tax_app_chg_logs clo
                         JOIN entity_table_map etm on (etm.table_name = clo.table_name)
                         JOIN juris_tax_app_qr q on (q.table_name = etm.table_name and q.ref_id = clo.primary_key)
                         -- Entity
                         AND etm.logical_entity = ''Taxability''
                         JOIN juris_tax_app_revisions rv on (rv.id = clo.rid)
                         JOIN juris_tax_applicabilities ar ON (ar.nkid = rv.nkid AND rev_join(ar.rid,rv.id,ar.next_rid) = 1)
                         -- Commodity
                         LEFT JOIN commodities com ON (com.id = ar.commodity_id) ';

        -- 1/29/2015 prep for Official Name
        --JOIN jurisdictions jr ON (jr.id = ar.jurisdiction_id) ';
        if pOfficialName is not null then
            s_Juris := ' JOIN jurisdictions jr ON (jr.id = ar.jurisdiction_id AND UPPER(jr.official_name) LIKE UPPER(''%'||pOfficialName||'%'') ) ';
        else
            s_Juris := ' JOIN jurisdictions jr ON (jr.id = ar.jurisdiction_id) ';
        end if;

        --  ,ar.rid juris_tax_imposition_rid
        --> Verified By
        sVerifiedBy := fnAndIs2(searchVar=>verifiedBy, dataCol=>'assigned_user_id');
        if length(sVerifiedBy)>1 then
            --sVerifiedBy := concat(sVerifiedBy,' or cva.assigned_user_id = any(cva.assigned_user_id) )');
            sVerifiedBy := concat(sVerifiedBy,' ');
        end if;

        --> Modified by
        sectionModifyBy := fnAndIs(searchVar=>search_ModifBy, dataCol=>'clo.entered_by');

        --> Reason
        sectionReason := fnAndIs(searchVar=>search_Reason, dataCol=>'cr.id');

        -- if performance hit; get this one later
        --> Associated Document Name
        sectionDocs := fnIsTextEntered(searchText=>search_Doc, dataCol=>'atc.display_name');

        -- reminder: display multiple
        --> Verified By
        sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');

        --> Data Range
        --sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'ar.status');
        sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'clo.status');

        --> Tags
        sectionTags := fnAndIs(searchVar=>search_Tags, dataCol=>'tgs.id');

        --> Citation ID if passed from Research Documentation
        sectionCit := fnAndIs(searchVar=>nCitationID, dataCol=>'ci.id');

        -- Main where
        --sq_whr := fnConvertINtoList(search_Verif,sVerifiedBy,4);
        sq_whr := concat(fnConvertINtoList(search_Verif, sVerifiedBy, 4), ' WHERE 1=1');
        IF search_Verif IS NOT NULL THEN
            sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');
        --  ELSE
        --      sq_whr :='WHERE 1=1';
        END IF;

        sq_whr := sq_whr || returnWhere(sdAfter=>modifAfter, sdBefore=>modifBefore);

        -- CONCAT {prefer || instead of nested CONCAT}
        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Verif || sq_Data || s_Juris || sq_Tags;
        sq_entity := sq_entity || sq_whr|| sectionModifyBy;
        sq_entity := sq_entity || sectionReason || sectionDocs || sectionVerif || sectionDataRange || sectionTags || sectionCit;

        select case when sectionVerif <> '' then ''
                    when sectionVerif <> '' and sVerifiedBy <> '' then 'AND '||sVerifiedBy||')'
                    else '' end
        into sVerifiedBy
        from dual;

        sq_Entity := sq_Entity|| sVerifiedBy;
        sq_Entity := sq_Entity|| grpBy_Default|| addgroupStmt;

        -- Columns for form {layout}
        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME, REFERENCE_CODE, table_name,
                                4 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
                                , TAG_NAME
                         FROM ( ';

        form_columns := form_columns || sq_entity ||') ORDER BY TO_DATE(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') DESC';
        --form_columns := q_rollup_qry||form_columns||sq_entity||'))';

        dbms_output.put_line(form_columns);

        OPEN p_ref FOR form_columns;
    END getTaxability;




    /*  -- Removed - CRAPP-2516
    -- CommGroups
    PROCEDURE getCommGroups(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
                            search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
                            modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
                            nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
                            p_ref OUT SYS_REFCURSOR)
    IS
        sq_Doc CLOB  := ' LEFT JOIN comm_grp_chg_cits cc ON (cc.comm_grp_chg_log_id = clo.id)
                          LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                          LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
        sq_Verif CLOB:= ' LEFT JOIN comm_grp_chg_vlds cva ON (cva.comm_grp_chg_log_id = clo.id)
                          LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
        sq_Tags CLOB := ' LEFT OUTER JOIN  commodity_group_tags admtgs on (admtgs.ref_nkid = ar.nkid)
                          LEFT OUTER JOIN Tags tgs ON (tgs.id = admtgs.tag_id) ';

        addgroupStmt CLOB := ',clo.status
                              ,clo.id
                              ,ar.name
                              ,ar.description
                              ,ar.id
                              ,ar.nkid
                              ,ar.rid
                              ,clo.rid
                              ,atc.id
                              ,cva.assigned_user_id ';

        -- ,ar.reference_code REFERENCE_CODE
        form_columns CLOB;
    BEGIN
    --                      , LISTAGG(ast.id||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''') WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id, ar.id)
    --                      , wm_concat(distinct atc.id) COL_DOC_ID_LIST    -- Changed to LISTAGG - CRAPP-2516

        sq_Main := ' SELECT DISTINCT
                            clo.id change_logId
                            , clo.rid COL_RID
                            , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                   WHEN clo.status = 1 THEN ''Locked''
                                   ELSE ''Pending''
                              END COL_PUBLISHED
                            , clo.entered_date COL_MODIFIED
                            , usr.firstname ||  '' '' ||usr.lastname COL_BY
                            , cr.reason COL_REASON
                            , LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                      WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id) AS COL_VERIFIED_BY
                            , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                            , ar.name COL_JNAME
                            , ar.description REFERENCE_CODE
                            , etm.ui_alias||'': ''||q.qr table_name
                            , ar.nkid COL_NKID
                            , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                            , clo.id jurisdiction_rid
                            , clo.rid juris_tax_imposition_rid
                            , '''' jurisdiction_nkid
                         FROM comm_grp_chg_logs clo
                    JOIN entity_table_map etm on (etm.table_name = clo.table_name)
                    JOIN comm_grp_qr q on (q.table_name = etm.table_name and q.ref_id = clo.primary_key)
                    -- Entity
                    AND etm.logical_entity = ''Commodity Group''
                    JOIN commodity_group_revisions rv ON (rv.id = clo.rid)
                    JOIN commodity_groups ar ON (ar.nkid = rv.nkid AND rev_join(ar.rid,rv.id,ar.next_rid) = 1) ';

        --> Verified By
        --  sVerifiedBy:=fnAndIs(searchVar=>verifiedBy, dataCol=>'cva.assigned_user_id');
        sVerifiedBy := fnAndIs2(searchVar=>verifiedBy, dataCol=>'assigned_user_id');
        if length(sVerifiedBy)>1 then
            sVerifiedBy:=concat(sVerifiedBy,' ');
        end if;

        --> Modified by
        sectionModifyBy := fnAndIs(searchVar=>search_ModifBy, dataCol=>'clo.entered_by');

        --> Reason
        sectionReason := fnAndIs(searchVar=>search_Reason, dataCol=>'cr.id');

        -- if performance hit; get this one later
        --> Associated Document Name
        sectionDocs := fnIsTextEntered(searchText=>search_Doc, dataCol=>'atc.display_name');

        -- reminder: display multiple
        --> Verified By
        sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');

        --> Data Range
        --sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'ar.status');
        sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'clo.status');

        --> Tags
        sectionTags := fnAndIs(searchVar=>search_Tags, dataCol=>'tgs.id');

        --> Citation ID if passed from Research Documentation
        sectionCit := fnAndIs(searchVar=>nCitationID, dataCol=>'ci.id');

        -- Main where
        --sq_whr := fnConvertINtoList(search_Verif,sVerifiedBy,6);
        sq_whr := concat(fnConvertINtoList(search_Verif, sVerifiedBy, 6), ' WHERE 1=1');
        IF search_Verif IS NOT NULL THEN
            sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');
        --  ELSE
        --      sq_whr :='WHERE 1=1';
        END IF;

        sq_whr := sq_whr || returnWhere(sdAfter=>modifAfter, sdBefore=>modifBefore);

        -- CONCAT {prefer || instead of nested CONCAT}
        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Verif || sq_Data || sq_Tags;
        sq_entity := sq_entity || sq_whr || sectionModifyBy;
        sq_entity := sq_entity || sectionReason || sectionDocs || sectionVerif || sectionDataRange|| sectionTags || sectionCit;

        select case when sectionVerif <> '' then ''
                    when sectionVerif <> '' and sVerifiedBy <> '' then 'AND '||sVerifiedBy||')'
                    else '' end
        into sVerifiedBy
        from dual;

        sq_Entity := sq_Entity|| sVerifiedBy;
        sq_Entity := sq_Entity|| grpBy_Default || addgroupStmt;

        -- Columns for form {layout}
        -- Either use this to select the specific columns or send back all of them to the app
        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME, REFERENCE_CODE, table_name,
                                6 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
                         FROM ( ';

        form_columns := form_columns || sq_entity ||') ORDER BY TO_DATE(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') DESC ';
        --form_columns:=q_rollup_qry||form_columns||sq_entity||'))';

        DBMS_OUTPUT.Put_Line( form_columns );

        OPEN p_ref FOR form_columns;
    END getCommGroups;
    */



    -- ******
    -- * Commodities
    -- ******
    PROCEDURE getCommodities(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
                             search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
                             modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
                             nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
                             p_ref OUT SYS_REFCURSOR)
    IS
        sq_Doc CLOB  := ' LEFT JOIN comm_chg_cits cc ON (cc.comm_chg_log_id = clo.id)
                          LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                          LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
        sq_Verif CLOB:= ' LEFT JOIN comm_chg_vlds cva ON (cva.comm_chg_log_id = clo.id)
                          LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
        sq_Tags CLOB := ' LEFT OUTER JOIN commodity_tags admtgs on (admtgs.ref_nkid = ar.nkid)
                          LEFT OUTER JOIN Tags tgs ON (tgs.id = admtgs.tag_id) ';
        addgroupStmt CLOB := ',clo.status
                              ,clo.rid
                              ,ar.name
                              ,tr.short_name
                              ,ar.nkid
                              ,ar.rid
                              ,clo.rid
                              ,atc.id
                              ,cva.assigned_user_id
                              ,tgs.name, tgs.id ';

        -- ,ar.reference_code REFERENCE_CODE
        form_columns CLOB;
    BEGIN
        --               , wm_concat(distinct atc.id) COL_DOC_ID_LIST    -- Changed to LISTAGG - CRAPP-2516

        sq_Main := 'SELECT DISTINCT
                           clo.id change_logId
                           , clo.rid COL_RID
                           , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                  WHEN clo.status = 1 THEN ''Locked''
                                  ELSE ''Pending''
                             END COL_PUBLISHED
                           , clo.entered_date COL_MODIFIED
                           , usr.firstname ||  '' '' ||usr.lastname COL_BY
                           , cr.reason COL_REASON
                           , regexp_replace(LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                     WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
                                     ,''([^,]+)(, \1)+'', ''\1'')
                                     AS COL_VERIFIED_BY
                           , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                           , ar.name COL_JNAME
                           , tr.short_name REFERENCE_CODE
                           , etm.ui_alias||'': ''||q.qr table_name
                           , ar.nkid COL_NKID
                           , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                           , clo.id jurisdiction_rid
                           , clo.rid juris_tax_imposition_rid
                           , '''' jurisdiction_nkid
                           , regexp_replace(LISTAGG(tgs.name, '','') WITHIN GROUP (ORDER BY tgs.id) over (PARTITION BY clo.id)
                           ,''([^,]+)(,\1)+'', ''\1'')
                           TAG_NAME
                    FROM comm_chg_logs clo
                         JOIN entity_table_map etm on (etm.table_name = clo.table_name)
                         JOIN comm_qr q on (q.table_name = etm.table_name and q.ref_id = clo.primary_key)
                         -- Entity
                         AND etm.logical_entity = ''Commodities''
                         JOIN commodity_revisions rv ON (rv.id = clo.rid)
                         JOIN commodities ar ON (ar.nkid = rv.nkid AND rev_join(ar.rid,rv.id,ar.next_rid) = 1)
                         JOIN product_trees tr on (tr.id = ar.product_tree_id) ';

        --> Verified By
        --sVerifiedBy := fnAndIs(searchVar=>verifiedBy, dataCol=>'cva.assigned_user_id');
        sVerifiedBy := fnAndIs2(searchVar=>verifiedBy, dataCol=>'assigned_user_id');
        if length(sVerifiedBy)>1 then
            sVerifiedBy := concat(sVerifiedBy,' ');
        end if;

        --> Modified by
        sectionModifyBy := fnAndIs(searchVar=>search_ModifBy, dataCol=>'clo.entered_by');

        --> Reason
        sectionReason := fnAndIs(searchVar=>search_Reason, dataCol=>'cr.id');

        -- if performance hit; get this one later
        --> Associated Document Name
        sectionDocs := fnIsTextEntered(searchText=>search_Doc, dataCol=>'atc.display_name');

        -- reminder: display multiple
        --> Verified By
        sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');

        --> Data Range
        --sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'ar.status');
        sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'clo.status');

        --> Tags
        sectionTags := fnAndIs(searchVar=>search_Tags, dataCol=>'tgs.id');

        --> Citation ID if passed from Research Documentation
        sectionCit := fnAndIs(searchVar=>nCitationID, dataCol=>'ci.id');

        -- Main where
        --sq_whr := fnConvertINtoList(search_Verif,sVerifiedBy,5);
        sq_whr := concat(fnConvertINtoList(search_Verif, sVerifiedBy, 5), ' WHERE 1=1');
        --sectionVerif:=' ';
        IF search_Verif IS NOT NULL THEN
            sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');
        --  ELSE
        --     sq_whr :='WHERE 1=1';
        END IF;

        sq_whr := sq_whr || returnWhere(sdAfter=>modifAfter, sdBefore=>modifBefore);

        -- CONCAT {prefer || instead of nested CONCAT}
        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Verif || sq_Data || sq_Tags;
        sq_entity := sq_entity || sq_whr|| sectionModifyBy;
        sq_entity := sq_entity || sectionReason || sectionDocs || sectionVerif || sectionDataRange || sectionTags || sectionCit;

        select case when sectionVerif <> '' then ''
                    when sectionVerif <> '' and sVerifiedBy <> '' then 'AND '||sVerifiedBy||')'
                    else '' end
        into sVerifiedBy
        from dual;

        sq_Entity := sq_Entity || sVerifiedBy;
        sq_Entity := sq_Entity || grpBy_Default|| addgroupStmt;

        -- Columns for form {layout}
        -- Either use this to select the specific columns or send back all of them to the app
        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME, REFERENCE_CODE, table_name,
                                5 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
                                , TAG_NAME
                         FROM ( ';

        form_columns := form_columns || sq_entity ||') ORDER BY TO_DATE(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') DESC ';
        --form_columns:=q_rollup_qry||form_columns||sq_entity||'))';

        dbms_output.put_line(form_columns);

        OPEN p_ref FOR form_columns;
    END getCommodities;




    /** ************************************************************************
    * Goods/Services
    * TEMP
    * Currently joining the two together - to consider; grab data into collection
    * and later build the list.
    */
    PROCEDURE getGoods(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
                       search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
                       modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
                       p_ref OUT SYS_REFCURSOR)
    IS
        -- (consider bit/integer)
        form_columns CLOB;
        clbProducts VARCHAR2(32767);
        clbServices VARCHAR2(32767);

        -- , wm_concat(distinct citations_id) COL_DOC_ID_LIST    -- Changed to LISTAGG - CRAPP-2516

        sq_main CLOB:='SELECT DISTINCT
                              gsType
                              , description
                              , change_logId
                              , COL_RID
                              , STATUS
                              , COL_PUBLISHED
                              , to_char(COL_MODIFIED,''mm/dd/yyyy HH24:mi:ss'') COL_MODIFIED
                              , COL_BY
                              , entered_by
                              , COL_REASON
                              , regexp_replace(LISTAGG(name, '', '') WITHIN GROUP (ORDER BY name) over (PARTITION BY change_logId)
                              ,''([^,]+)(, \1)+'', ''\1'')
                              AS COL_VERIFIED_BY
                              , ''Documents(''||nvl(count(attachment_id),0)||'')'' COL_DOCUMENTS
                              , TREE
                              , GS_NAME
                              , table_name
                              , NKID COL_NKID
                              , LISTAGG(citations_id, '','') WITHIN GROUP (ORDER BY citations_id) over (PARTITION BY change_logId) COL_DOC_ID_LIST
                              , '''' jurisdiction_rid
                              , '''' juris_tax_imposition_rid ';

        sq_group CLOB := 'GROUP BY gsType, description, change_logId, COL_RID
                                   ,STATUS, COL_PUBLISHED, COL_MODIFIED, COL_BY, entered_by, COL_REASON, table_name
                                   ,NKID, tree, NAME, GS_NAME, citations_id ';
        stw CLOB;

    BEGIN
        --> Modified by
        sectionModifyBy := fnAndIs(searchVar=>search_ModifBy, dataCol=>'entered_by');

        --> Reason
        sectionReason := fnAndIs(searchVar=>search_Reason, dataCol=>'change_reason');

        -- if performance hit; get this one later
        --> Associated Document Name
        sectionDocs := fnIsTextEntered(searchText=>search_Doc, dataCol=>'text');

        --> Verified By
        sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'assignment_type_id');

        --> Data Range
        sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'status');

        --> Tags
        -- no tags for goods/serv
        -- sectionTags := fnAndIs(searchVar=>search_Tags, dataCol=>'tgs.id');

        IF modifAfter IS NOT NULL THEN
            stw := stw ||' AND entered_date>=to_date('''||modifAfter||''',''DD-MON-YYYY'')';
        END IF;

        IF modifBefore IS NOT NULL THEN
            stw := stw ||' AND entered_date<=TO_DATE('''||modifBefore||''',''DD-MON-YYYY'')';
        END IF;


        ------------------------------------------------------------------------
        -- Prod [Section 5.A]
        -- WHERE
        IF search_Verif IS NOT NULL THEN
            sq_whr := fndashinconvert(search_Verif,5);
            sectionVerif:=' ';
        ELSE
            sq_whr := 'WHERE 1=1';
        END IF;

        sq_whr := sq_whr || sectionModifyBy|| sectionReason|| sectionDocs|| sectionVerif|| sectionDataRange;
        sq_whr := sq_whr || stw;
        clbProducts := sq_Main||'FROM nnt_changelog_prod_v '|| sq_whr ||' '|| sq_group;

        ------------------------------------------------------------------------
        -- same for services
        -- Services [Section 5.B]
        -- WHERE
        /*
        IF search_Verif IS NOT NULL THEN
            sq_whr := fndashINConvert(search_Verif,5);
        ELSE
            sq_whr :='WHERE 1=1';
        END IF;
        sq_whr := sectionModifyBy|| sectionReason|| sectionDocs|| sectionVerif|| sectionDataRange;
        sq_whr := sq_whr || stw;
        */

        clbServices := sq_Main || 'FROM nnt_changelog_serv_v '|| sq_whr ||' '|| sq_group;

        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, TREE, GS_NAME, table_name,
                                5 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid
                                , juris_tax_imposition_rid
                                , TAG_NAME
                         FROM ( '|| trim(clbProducts) || ' UNION ALL '|| trim(clbServices)||')';

        OPEN p_ref FOR form_columns;
    END getGoods;




    -- ******
    -- * Reference Groups
    -- ******
    PROCEDURE getRefGroups(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
                           search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
                           modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
                           nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
                           p_ref OUT SYS_REFCURSOR)
    IS
        sq_Doc CLOB  := ' LEFT JOIN ref_grp_chg_cits cc ON (cc.ref_grp_chg_log_id = clo.id)
                          LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                          LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
        sq_Verif CLOB:= ' LEFT JOIN ref_grp_chg_vlds cva ON (cva.ref_grp_chg_log_id = clo.id)
                          LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
        sq_Tags CLOB := ' LEFT OUTER JOIN ref_group_tags admtgs on (admtgs.ref_nkid = ar.nkid)
                          LEFT OUTER JOIN Tags tgs ON (tgs.id = admtgs.tag_id) ';
        addgroupStmt CLOB := ',clo.status
                              ,clo.rid
                              ,ar.name
                              ,ar.nkid
                              ,ar.rid
                              ,clo.rid
                              ,atc.id
                              ,cva.assigned_user_id
                              ,tgs.name, tgs.id ';
        -- ,ar.reference_code REFERENCE_CODE

        form_columns CLOB;
    BEGIN
        -- , wm_concat(distinct atc.id) COL_DOC_ID_LIST    -- Changed to LISTAGG - CRAPP-2516

        sq_Main := 'SELECT DISTINCT
                           clo.id change_logId
                           , clo.rid COL_RID
                           , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                  WHEN clo.status = 1 THEN ''Locked''
                                  ELSE ''Pending''
                             END COL_PUBLISHED
                           , clo.entered_date COL_MODIFIED
                           , usr.firstname ||  '' '' ||usr.lastname COL_BY
                           , cr.reason COL_REASON
                           , regexp_replace(LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                     WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
                                     ,''([^,]+)(, \1)+'', ''\1'')
                                     AS COL_VERIFIED_BY
                           , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                           , ar.name COL_JNAME
                           , '' '' REFERENCE_CODE
                           , etm.ui_alias||'': ''||q.qr table_name
                           , ar.nkid COL_NKID
                           , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                           , clo.id jurisdiction_rid
                           , clo.rid juris_tax_imposition_rid
                           , '''' jurisdiction_nkid
                           , regexp_replace(LISTAGG(tgs.name, '','') WITHIN GROUP (ORDER BY tgs.id) over (PARTITION BY clo.id)
                           ,''([^,]+)(,\1)+'', ''\1'')
                           TAG_NAME
                    FROM ref_grp_chg_logs clo
                         JOIN entity_table_map etm on (etm.table_name = clo.table_name)
                         JOIN ref_grp_qr q on (q.table_name = etm.table_name and q.ref_id = clo.primary_key)
                         -- Entity
                         AND etm.logical_entity = ''Reference Group''
                         JOIN ref_group_revisions rv ON (rv.id = clo.rid)
                         JOIN reference_groups ar ON (ar.nkid = rv.nkid AND rev_join(ar.rid,rv.id,ar.next_rid) = 1) ';

        --> Verified By
        --sVerifiedBy := fnAndIs(searchVar=>verifiedBy, dataCol=>'cva.assigned_user_id');
        sVerifiedBy := fnAndIs2(searchVar=>verifiedBy, dataCol=>'assigned_user_id');
        if length(sVerifiedBy)>1 then
            sVerifiedBy := concat(sVerifiedBy,' ');
        end if;

        --> Modified by
        sectionModifyBy := fnAndIs(searchVar=>search_ModifBy, dataCol=>'clo.entered_by');

        --> Reason
        sectionReason := fnAndIs(searchVar=>search_Reason, dataCol=>'cr.id');

        -- if performance hit; get this one later
        --> Associated Document Name
        sectionDocs := fnIsTextEntered(searchText=>search_Doc, dataCol=>'atc.display_name');

        -- reminder: display multiple
        --> Verified By
        sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');

        --> Data Range
        --sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'ar.status');
        sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'clo.status');

        --> Tags
        sectionTags := fnAndIs(searchVar=>search_Tags, dataCol=>'tgs.id');

        --> Citation ID if passed from Research Documentation
        sectionCit := fnAndIs(searchVar=>nCitationID, dataCol=>'ci.id');

        -- Main where
        --sq_whr := fnConvertINtoList(search_Verif,sVerifiedBy,9);
        sq_whr := concat(fnConvertINtoList(search_Verif, sVerifiedBy, 9), ' WHERE 1=1');
        IF search_Verif IS NOT NULL THEN
            sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');
        --ELSE
        --   sq_whr :='WHERE 1=1';
        END IF;

        sq_whr := sq_whr || returnWhere(sdAfter=>modifAfter, sdBefore=>modifBefore);
        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Verif || sq_Data || sq_Tags;
        sq_entity := sq_entity || sq_whr || sectionModifyBy;
        sq_entity := sq_entity || sectionReason || sectionDocs || sectionVerif || sectionDataRange || sectionTags || sectionCit;

        select case when sectionVerif <> '' then ''
                    when sectionVerif <> '' and sVerifiedBy <> '' then 'AND '||sVerifiedBy||')'
                    else '' end
        into sVerifiedBy
        from dual;

        sq_Entity := sq_Entity || sVerifiedBy;
        sq_Entity := sq_Entity || grpBy_Default|| addgroupStmt;

        -- Columns for form {layout}
        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME, REFERENCE_CODE, table_name,
                                9 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
                                , TAG_NAME
                         FROM ( ';

        form_columns := form_columns || sq_entity ||') ORDER BY TO_DATE(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') DESC ';
        dbms_output.put_line(form_columns);

        OPEN p_ref FOR form_columns;
    END getRefGroups;



    /** previous version: Search
    *  Old test procedure
    *  rev: 0.1
    */
    PROCEDURE pt_search_changelog(entity IN varchar2,
              search_ModifBy IN VARCHAR2,
              search_Reason  IN VARCHAR2,
              search_Doc     IN VARCHAR2,
              search_Verif   IN VARCHAR2,
              search_Data    IN VARCHAR2,
              search_Tags    IN VARCHAR2,
              modifAfter     IN VARCHAR2 DEFAULT NULL,
              modifBefore    IN VARCHAR2 DEFAULT NULL,
              verifiedBy     IN VARCHAR2 DEFAULT NULL,
              p_ref_ad OUT SYS_REFCURSOR,
              p_ref_ju OUT SYS_REFCURSOR,
              p_ref_tx OUT sys_refcursor,
              p_ref_ta OUT sys_refcursor,
              p_ref_cm OUT sys_refcursor,
              p_ref_cg OUT sys_refcursor
    ) IS
        nCitationID NUMBER :=NULL;
    BEGIN

        --> 1 Administrator
        IF instr(entity,'1')>0 THEN
            getAdmin(search_ModifBy, search_Reason, search_Doc,
                     search_Verif, search_Data, search_Tags,
                     modifAfter , modifBefore ,
                     nCitationID, verifiedBy,
                     p_ref_ad);
        END IF;

        --> 2 Jurisdiction
        IF instr(entity,'2')>0 THEN
            getJurisdiction(search_ModifBy, search_Reason, search_Doc,
                            search_Verif, search_Data, search_Tags,
                            modifAfter , modifBefore ,
                            nCitationID, verifiedBy,
                            p_ref_ju);
        END IF;

        --> 3 Tax
        IF instr(entity,'3')>0 THEN
            getTax(search_ModifBy, search_Reason, search_Doc,
                   search_Verif, search_Data, search_Tags,
                   modifAfter , modifBefore ,
                   nCitationID, verifiedBy,
                   p_ref_tx);
        END IF;

        --> 4 Taxability
        IF instr(entity,'4')>0 THEN
            getTaxability(search_ModifBy, search_Reason, search_Doc,
                          search_Verif, search_Data, search_Tags,
                          modifAfter , modifBefore ,
                          nCitationID, verifiedBy,
                          p_ref_ta);
        END IF;

        --> 5 Commoditites
        IF instr(entity,'5')>0 THEN
            getCommodities(search_ModifBy, search_Reason, search_Doc,
                           search_Verif, search_Data, search_Tags,
                           modifAfter , modifBefore ,
                           nCitationID, verifiedBy,
                           p_ref_cm);
        END IF;

        /* -- Removed - CRAPP-2516
        --> 6 Commodity Groups
        IF instr(entity,'6')>0 THEN
            getCommGroups(search_ModifBy, search_Reason, search_Doc,
                          search_Verif, search_Data, search_Tags,
                          modifAfter , modifBefore ,
                          nCitationID, verifiedBy,
                          p_ref_cg);
        END IF;
        */
    END;




    /** ---------------------------------------------------------------------- **/

    /** Main Function
    *  SearchLog
    *  rev: 0.3
    *  Using same data type record for all sections at this time
    *  (could be confusing since all sections will have same column names)
    *  --> each section should probably have their own dataRecord (type:outSet)
    */
    FUNCTION searchLog(entity IN VARCHAR2,
              search_ModifBy  IN VARCHAR2,
              search_Reason   IN VARCHAR2,
              search_Doc      IN VARCHAR2,
              search_Verif    IN VARCHAR2,
              search_Data     IN VARCHAR2,
              search_Tags     IN VARCHAR2,
              modifAfter      IN VARCHAR2 DEFAULT NULL,
              modifBefore     IN VARCHAR2 DEFAULT NULL,
              verifiedBy      IN VARCHAR2 DEFAULT NULL,
              pOfficialName   IN VARCHAR2 DEFAULT NULL
    )
    RETURN outTable PIPELINED IS

        -- All sections are using the same out format
        dataRecord outSet;

        cursor_ju SYS_REFCURSOR;
        cursor_ad SYS_REFCURSOR;
        cursor_tx SYS_REFCURSOR;
        cursor_ta SYS_REFCURSOR;
        cursor_gs SYS_REFCURSOR;
        --cursor_cg SYS_REFCURSOR;   -- Removed - CRAPP-2516
        cursor_cm SYS_REFCURSOR;
        cursor_rf sys_refcursor;
        cursor_geop sys_refcursor;
        cursor_geoa sys_refcursor;

        nCitationID NUMBER :=NULL;
    BEGIN

        --> 1 Admin
        IF entity in('1') THEN
            getAdmin(search_ModifBy, search_Reason, search_Doc,
                     search_Verif, search_Data, search_Tags,
                     modifAfter , modifBefore ,
                     nCitationID, verifiedBy,
                     cursor_ad);
        END IF;

        --> 2 Juris
        IF entity in('2') THEN
            getJurisdiction(search_ModifBy, search_Reason, search_Doc,
                            search_Verif, search_Data, search_Tags,
                            modifAfter , modifBefore ,
                            nCitationID, verifiedBy,
                            cursor_ju
                            , pOfficialName);
        END IF;

        --> 3 Tax
        IF entity in('3') THEN
            getTax(search_ModifBy, search_Reason, search_Doc,
                   search_Verif, search_Data, search_Tags,
                   modifAfter , modifBefore ,
                   nCitationID, verifiedBy,
                   cursor_tx
                   , pOfficialName);
        END IF;

        --> 4 Taxability
        IF entity in('4') THEN
            getTaxability(search_ModifBy, search_Reason, search_Doc,
                          search_Verif, search_Data, search_Tags,
                          modifAfter , modifBefore ,
                          nCitationID, verifiedBy,
                          cursor_ta
                          , pOfficialName);
        END IF;

        --> 5 Commidities
        IF entity in('5') THEN
            getCommodities(search_ModifBy, search_Reason, search_Doc,
                           search_Verif, search_Data, search_Tags,
                           modifAfter , modifBefore ,
                           nCitationID, verifiedBy,
                           cursor_cm);
        END IF;


        /*  -- Removed - CRAPP-2516
        --> 6 Commodity Group
        IF entity in('6') THEN
            getCommGroups(search_ModifBy, search_Reason, search_Doc,
                          search_Verif, search_Data, search_Tags,
                          modifAfter , modifBefore ,
                          nCitationID, verifiedBy,
                          cursor_cg);
        END IF;
        */

        --> 9 Reference Groups
        IF entity in('9') THEN
            getRefGroups(search_ModifBy, search_Reason, search_Doc,
                         search_Verif, search_Data, search_Tags,
                         modifAfter , modifBefore ,
                         nCitationID, verifiedBy,
                         cursor_rf);
        END IF;


        --> Boundaries
        IF entity in('10') THEN
            getGeoPolygons(search_ModifBy, search_Reason, search_Doc,
                           search_Verif, search_Data, search_Tags,
                           modifAfter , modifBefore ,
                           nCitationID, verifiedBy,
                           cursor_geop
                           , pOfficialName);
        END IF;


        --> Unique Areas
        IF entity in('11') THEN
            getGeoUniqueAreas(search_ModifBy, search_Reason, search_Doc,
                              search_Verif, search_Data, search_Tags,
                              modifAfter , modifBefore ,
                              nCitationID, verifiedBy,
                              cursor_geoa
                              , pOfficialName);
        END IF;


        -- future dev; one proc - pass in cursor
        IF cursor_ad%ISOPEN THEN
            LOOP
                FETCH cursor_ad INTO dataRecord;
                EXIT WHEN cursor_ad%NOTFOUND;
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_ad;
        END IF;


        IF cursor_ju%ISOPEN THEN
            LOOP
                FETCH cursor_ju INTO dataRecord;
                EXIT WHEN cursor_ju%NOTFOUND;
                -- FETCH cursor_ad BULK COLLECT INTO
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_ju;
        END IF;

        IF cursor_tx%ISOPEN THEN
            LOOP
                FETCH cursor_tx INTO dataRecord;
                EXIT WHEN cursor_tx%NOTFOUND;
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_tx;
        END IF;

        IF cursor_ta%ISOPEN THEN
            LOOP
                FETCH cursor_ta INTO dataRecord;
                EXIT WHEN cursor_ta%NOTFOUND;
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_ta;
        END IF;

       IF cursor_cm%ISOPEN THEN
            LOOP
                FETCH cursor_cm INTO dataRecord;
                EXIT WHEN cursor_cm%NOTFOUND;
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_cm;
        END IF;

        /*  -- Removed - CRAPP-2516
        IF cursor_cg%ISOPEN THEN
            LOOP
                FETCH cursor_cg INTO dataRecord;
                EXIT WHEN cursor_cg%NOTFOUND;
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_cg;
        END IF;
        */

        IF cursor_rf%ISOPEN THEN
            LOOP
                FETCH cursor_rf INTO dataRecord;
                EXIT WHEN cursor_rf%NOTFOUND;
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_rf;
        END IF;

        IF cursor_geop%ISOPEN THEN
            LOOP
                FETCH cursor_geop INTO dataRecord;
                EXIT WHEN cursor_geop%NOTFOUND;
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_geop;
        END IF;

        IF cursor_geoa%ISOPEN THEN
            LOOP
                FETCH cursor_geoa INTO dataRecord;
                EXIT WHEN cursor_geoa%NOTFOUND;
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_geoa;
        END IF;

        RETURN;
    END searchLog;




    /** Citation ID -- temp out function
    *  1/ IN citation ID, entity [out pipelined 1 section at the time]
    *  2/ IN citation ID [out pipelined all sections to temp table] - might be slow
    */
    FUNCTION searchCitation(search_citationID IN number) RETURN outTable_CID PIPELINED IS
        dataRecord outSet_Citation;
        cursor_cit SYS_REFCURSOR;
    BEGIN
        getCitation(search_citationID, cursor_cit);
        IF cursor_cit%ISOPEN THEN
            LOOP
                FETCH cursor_cit INTO dataRecord;
                EXIT WHEN cursor_cit%NOTFOUND;
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_cit;
        END IF;
        RETURN;
    END;




    /** Citation ID :: ADMIN
    *  Test procedure for entity ADMIN
    *  ToDo: add rid columns for entity type 3
    */
    PROCEDURE getCitation(cit_id IN number, p_ref OUT SYS_REFCURSOR) IS
        form_columns CLOB;
        sq_whr CLOB;
    BEGIN
        -- nCitationID IN NUMBER DEFAULT NULL

        sq_Main := '(SELECT * FROM
                        ( (select id, CHANGE_LOGID, COL_RID, COL_PUBLISHED,
                            COL_MODIFIED, COL_BY, COL_REASON,
                            COL_VERIFIED_BY, COL_DOCUMENTS, COL_ADMINISTRATOR COL_SCT_ATTRIBUTE, REFERENCE_CODE,
                            table_name, 1 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                            ,'''' jurisdiction_rid
                            ,'''' juris_tax_imposition_rid
                          FROM chng_log_entity1_v)
                          UNION ALL
                          (select id, CHANGE_LOGID, COL_RID, COL_PUBLISHED, COL_MODIFIED, COL_BY, COL_REASON,
                            COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME COL_SCT_ATTRIBUTE, REFERENCE_CODE, table_name,
                            2 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                            ,'''' jurisdiction_rid
                            ,'''' juris_tax_imposition_rid
                          FROM chng_log_entity2_v)
                          UNION ALL
                          (select id, CHANGE_LOGID, COL_RID, COL_PUBLISHED, COL_MODIFIED, COL_BY, COL_REASON,
                            COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME COL_SCT_ATTRIBUTE, REFERENCE_CODE, table_name,
                            3 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                            ,to_char(jurisdiction_rid) jurisdiction_rid
                            ,to_char(juris_tax_imposition_rid) juris_tax_imposition_rid
                          FROM chng_log_entity3_v)
                          UNION ALL
                          (select id, CHANGE_LOGID, COL_RID, COL_PUBLISHED, COL_MODIFIED, COL_BY, COL_REASON,
                            COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME COL_SCT_ATTRIBUTE, REFERENCE_CODE, table_name,
                            4 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                            ,'''' jurisdiction_rid
                            ,'''' juris_tax_imposition_rid
                          FROM chng_log_entity4_v)
                        )';

                        /*UNION ALL
                        (select cit_id ID, CHANGE_LOGID, COL_RID, COL_PUBLISHED, COL_MODIFIED, COL_BY, COL_REASON,
                            COL_VERIFIED_BY, COL_DOCUMENTS, TREE COL_SCT_ATTRIBUTE, GS_NAME REFERENCE_CODE, table_name,
                            5 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                            ,'''' jurisdiction_rid
                            ,'''' juris_tax_imposition_rid
                            FROM chng_log_entity5_v))';*/

        IF cit_id IS NOT NULL THEN
            sq_whr :=' WHERE id = '||cit_id||')';
        END IF;

        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED,
                                to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, COL_SCT_ATTRIBUTE, REFERENCE_CODE,
                                table_name, SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid
                                , juris_tax_imposition_rid
                         FROM '|| sq_Main || sq_whr;

        OPEN p_ref FOR form_columns;

    END getCitation;




    -- Boundaries --
    PROCEDURE getGeoPolygons(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
                             search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
                             modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
                             nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
                             p_ref OUT SYS_REFCURSOR, pOfficialName IN VARCHAR2 DEFAULT NULL)
    IS
        --
        -- Jurisdiction {var}
        --
        sq_Doc CLOB  := ' LEFT JOIN geo_poly_ref_chg_cits cc ON (cc.geo_poly_ref_chg_log_id = clo.id)
                          LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                          LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
        sq_Verif CLOB:= ' LEFT JOIN geo_poly_ref_chg_vlds cva ON (cva.geo_poly_ref_chg_log_id = clo.id)
                          LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
        sq_Tags CLOB := ' LEFT OUTER JOIN geo_polygon_tags admtgs on (admtgs.ref_nkid = ar.nkid)
                          LEFT OUTER JOIN Tags tgs ON (tgs.id = admtgs.tag_id) ';
        addgroupStmt CLOB := ',clo.status
                              ,clo.rid
                              ,ar.geo_area_key
                              ,ar.nkid
                              ,atc.id
                              ,cva.assigned_user_id ';
        form_columns CLOB;
        s_Juris CLOB;
    BEGIN
        -- 0 pending
        -- 1 locked
        -- 2 published
        -- ,''Documents(''||nvl(count(distinct ci.attachment_id),0)||'')'' COL_DOCUMENTS
        -- , wm_concat(distinct atc.id) COL_DOC_ID_LIST    -- Changed to LISTLAGG - CRAPP-2516


        sq_Main := 'SELECT DISTINCT
                           clo.id change_logId
                           , clo.rid COL_RID
                           , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                  WHEN clo.status = 1 THEN ''Locked''
                                  ELSE ''Pending''
                             END COL_PUBLISHED
                           , clo.entered_date COL_MODIFIED
                           , usr.firstname ||  '' '' ||usr.lastname COL_BY
                           , cr.reason COL_REASON
                           , regexp_replace(LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                     WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
                                     ,''([^,]+)(, \1)+'', ''\1'')
                                     AS COL_VERIFIED_BY
                           , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                           , ar.geo_area_key COL_JNAME
                           , '' '' REFERENCE_CODE
                           , etm.ui_alias||'': ''||q.qr table_name
                           , ar.nkid COL_NKID
                           , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                           , '''' jurisdiction_rid
                           , '''' juris_tax_imposition_rid
                           , '''' jurisdiction_nkid
                    FROM geo_poly_ref_chg_logs clo
                         JOIN entity_table_map etm on (etm.table_name = clo.table_name)
                         JOIN (select 1 qr from dual) q on (1=1)
                         -- Entity
                         AND etm.logical_entity = ''Boundaries''
                         -- base data
                         JOIN geo_poly_ref_revisions rv ON (rv.id = clo.rid)
                         JOIN geo_polygons ar ON (rv.nkid = ar.nkid AND rev_join(ar.rid,rv.id,ar.next_rid) = 1) ';

        -- TEST! Either join or outside (simple unsec parameter) --
        if pOfficialName is not null then
            s_Juris:=' JOIN juris_geo_areas jga ON (jga.geo_polygon_id = ar.id)
                       JOIN jurisdictions jmain ON (jga.jurisdiction_id = jmain.id
                                                    AND UPPER(jmain.official_name) LIKE UPPER(''%'||pOfficialName||'%'')) ';
        else
            s_Juris:='';
        end if;
        -- TEST --

        sVerifiedBy := fnAndIs2(searchVar=>verifiedBy, dataCol=>'assigned_user_id');

        if length(sVerifiedBy)>1 then
            sVerifiedBy:=concat(sVerifiedBy,' ');
        end if;

        --> Modified by
        sectionModifyBy := fnAndIs(searchVar=>search_ModifBy, dataCol=>'clo.entered_by');

        --> Reason
        sectionReason := fnAndIs(searchVar=>search_Reason, dataCol=>'cr.id');

        -- if performance hit; get this one later
        --> Associated Document Name
        sectionDocs := fnIsTextEntered(searchText=>search_Doc, dataCol=>'atc.display_name');

        -- reminder: display multiple
        --> Verified By
        sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');

        --> Data Range
        --sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'ar.status');
        sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'clo.status');

        --> Tags
        sectionTags := fnAndIs(searchVar=>search_Tags, dataCol=>'tgs.id');

        --> Citation ID if passed from Research Documentation
        sectionCit := fnAndIs(searchVar=>nCitationID, dataCol=>'ci.id');

        -- Main where
        sq_whr := concat(fnConvertINtoList(search_Verif, sVerifiedBy, 10), ' WHERE 1=1');
        IF search_Verif IS NOT NULL THEN
            sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');
        --ELSE
        --    sq_whr :='WHERE 1=1';
        END IF;

        sq_whr := sq_whr || returnWhere(sdAfter=>modifAfter, sdBefore=>modifBefore);

        -- CONCAT {prefer || instead of nested CONCAT}
        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Verif || sq_Data || s_Juris || sq_Tags;
        sq_entity := sq_entity || sq_whr|| sectionModifyBy;
        sq_entity := sq_entity || sectionReason || sectionDocs || sectionVerif || sectionDataRange || sectionTags || sectionCit;

        select case when sectionVerif <> '' then ''
                    when sectionVerif <> '' and sVerifiedBy <> '' then 'AND '||sVerifiedBy||')'
                    else '' end
        into sVerifiedBy
        from dual;

        sq_Entity := sq_Entity || sVerifiedBy;
        sq_Entity := sq_Entity || grpBy_Default || addgroupStmt;

        -- Columns for form {layout}
        -- Either use this to select the specific columns or send back all of them to the app
        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME, REFERENCE_CODE, table_name,
                                10 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
                         FROM ( ';

        form_columns := form_columns || sq_entity ||') ORDER BY TO_DATE(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') DESC ';

        dbms_output.put_line(form_columns);
        OPEN p_ref FOR form_columns;
    END getGeoPolygons;



    -- Unique Areas --
    PROCEDURE getGeoUniqueAreas(search_ModifBy IN VARCHAR2, search_Reason IN VARCHAR2, search_Doc IN VARCHAR2,
                                search_Verif IN VARCHAR2, search_Data IN VARCHAR2, search_Tags IN VARCHAR2,
                                modifAfter IN VARCHAR2 DEFAULT NULL, modifBefore IN VARCHAR2 DEFAULT NULL,
                                nCitationID IN VARCHAR2 DEFAULT NULL, verifiedBy IN VARCHAR2 DEFAULT NULL,
                                p_ref OUT SYS_REFCURSOR, pOfficialName IN VARCHAR2 DEFAULT NULL)
    IS

        sq_Doc CLOB  := ' LEFT JOIN geo_unique_area_chg_cits cc ON (cc.geo_unique_area_chg_log_id = clo.id)
                          LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                          LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
        sq_Verif CLOB:= ' LEFT JOIN geo_unique_area_chg_vlds cva ON (cva.geo_unique_area_chg_log_id = clo.id)
                          LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
        sq_Tags CLOB := ' LEFT OUTER JOIN geo_unique_area_tags admtgs on (admtgs.ref_nkid = ar.nkid)
                          LEFT OUTER JOIN Tags tgs ON (tgs.id = admtgs.tag_id) ';
        addgroupStmt CLOB := ',clo.status
                              ,clo.rid
                              ,ar.unique_area
                              ,ar.nkid
                              ,atc.id
                              ,cva.assigned_user_id ';
        form_columns CLOB;
        s_Juris CLOB;

    BEGIN
        -- 0 pending
        -- 1 locked
        -- 2 published
        -- ,''Documents(''||nvl(count(distinct ci.attachment_id),0)||'')'' COL_DOCUMENTS
        -- , wm_concat(distinct atc.id) COL_DOC_ID_LIST    -- Changed to LISTLAGG - CRAPP-2516

        sq_Main := 'SELECT DISTINCT
                           clo.id change_logId
                           , clo.rid COL_RID
                           , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                  WHEN clo.status = 1 THEN ''Locked''
                                  ELSE ''Pending''
                             END COL_PUBLISHED
                           , clo.entered_date COL_MODIFIED
                           , usr.firstname ||  '' '' ||usr.lastname COL_BY
                           , cr.reason COL_REASON
                           , regexp_replace(LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                     WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
                                     ,''([^,]+)(, \1)+'', ''\1'')
                                     AS COL_VERIFIED_BY
                           , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                           , ar.unique_area COL_JNAME
                           , '' '' REFERENCE_CODE
                           , etm.ui_alias||'': ''||q.qr table_name
                           , ar.nkid COL_NKID
                           , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                           , '''' jurisdiction_rid
                           , '''' juris_tax_imposition_rid
                           , '''' jurisdiction_nkid
                    FROM geo_unique_area_chg_logs clo
                         JOIN entity_table_map etm on (etm.table_name = clo.table_name)
                         JOIN (select 1 qr from dual) q on (1=1)
                         -- Entity
                         AND etm.logical_entity = ''Unique Areas''
                         -- base data
                         JOIN geo_unique_area_revisions rv ON (rv.id = clo.rid)
                         JOIN vunique_areas ar ON (rv.nkid = ar.nkid AND rev_join(ar.rid,rv.id,ar.next_rid) = 1) ';

                         --JOIN geo_unique_areas ar ON (rv.nkid = ar.nkid AND rev_join(ar.rid,rv.id,ar.next_rid) = 1) ';

        -- TEST! Either join or outside (simple unsec parameter) --
        if pOfficialName is not null then
            s_Juris:='JOIN (SELECT gpl.unique_area_id
                            FROM geo_unique_area_polygons gpl
                                 JOIN (SELECT *
                                       FROM juris_geo_areas jga
                                            JOIN jurisdictions jr on (jga.jurisdiction_id=jr.id)
                                       WHERE UPPER(jr.official_name) LIKE UPPER(''%'||pOfficialName||'%'')
                                      ) g_area on (g_area.geo_polygon_id = gpl.geo_polygon_id)
                           ) SrchJuris ON (SrchJuris.unique_area_id = clo.entity_id) ';
        else
            s_Juris:='';
        end if;
        -- TEST --

        sVerifiedBy := fnAndIs2(searchVar=>verifiedBy, dataCol=>'assigned_user_id');

        if length(sVerifiedBy)>1 then
           sVerifiedBy := concat(sVerifiedBy,' ');
        end if;

        --> Modified by
        sectionModifyBy := fnAndIs(searchVar=>search_ModifBy, dataCol=>'clo.entered_by');

        --> Reason
        sectionReason := fnAndIs(searchVar=>search_Reason, dataCol=>'cr.id');

        -- if performance hit; get this one later
        --> Associated Document Name
        sectionDocs := fnIsTextEntered(searchText=>search_Doc, dataCol=>'atc.display_name');

        -- reminder: display multiple
        --> Verified By
        sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');

        --> Data Range
        --sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'ar.status');
        sectionDataRange := fnAndIs(searchVar=>search_Data, dataCol=>'clo.status');

        --> Tags
        sectionTags := fnAndIs(searchVar=>search_Tags, dataCol=>'tgs.id');

        --> Citation ID if passed from Research Documentation
        sectionCit := fnAndIs(searchVar=>nCitationID, dataCol=>'ci.id');

        -- Main where
        sq_whr :=concat(fnConvertINtoList(search_Verif, sVerifiedBy, 11), ' WHERE 1=1');
        IF search_Verif IS NOT NULL THEN
            sectionVerif := fnAndIs(searchVar=>search_Verif, dataCol=>'ast.id');
        --ELSE
        --    sq_whr :='WHERE 1=1';
        END IF;

        sq_whr := sq_whr || returnWhere(sdAfter=>modifAfter, sdBefore=>modifBefore);

        -- CONCAT {prefer || instead of nested CONCAT}
        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Verif || sq_Data || s_Juris || sq_Tags;
        sq_entity := sq_entity || sq_whr|| sectionModifyBy;
        sq_entity := sq_entity || sectionReason || sectionDocs || sectionVerif || sectionDataRange || sectionTags || sectionCit;

        select case when sectionVerif<>'' then ''
               when sectionVerif<>'' and sVerifiedBy<>'' then 'AND '||sVerifiedBy||')'
               else '' end
        into sVerifiedBy
        from dual;

        sq_Entity := sq_Entity || sVerifiedBy;
        sq_Entity := sq_Entity || grpBy_Default || addgroupStmt;

        -- Columns for form {layout}
        -- Either use this to select the specific columns or send back all of them to the app
        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME, REFERENCE_CODE, table_name,
                                11 SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
                         FROM (';

        form_columns := form_columns || sq_entity ||') ORDER BY TO_DATE(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') DESC ';

        dbms_output.put_line(form_columns);
        OPEN p_ref FOR form_columns;
    end getGeoUniqueAreas;




    FUNCTION retUpdateMultipleSet(pProcessId IN NUMBER) RETURN t_feed pipelined
    IS
        lo_feed r_feed;
    BEGIN
        for r_row in (SELECT lg.process_id, lg.primary_key, lg.eid
                      FROM  update_multiple_log lg
                      WHERE lg.process_id = pProcessId
                            and decode(lg.primary_key,0,0,null,0,1) = 1)
        loop
            lo_feed.process_id  := r_row.process_id;
            lo_feed.primary_key := r_row.primary_key;
            lo_feed.eid := r_row.eid;
            pipe row(lo_feed);
        end loop;
    END retUpdateMultipleSet;



    /*procedure getUpdateMultiple(pProcessId in number, p_ref OUT SYS_REFCURSOR) is
        l_entity update_multiple_log.entity%type;
        change_table varchar2(30);
    begin
        -- New dev 4/23/2015
            -- get process id from update multiple log
            -- get entity type and change log primary keys
            -- call get procedure to build search
            -- open ref cursor for form_columns
            Select distinct entity into l_entity
            from update_multiple_log
            where process_id = pProcessId;
            DBMS_OUTPUT.Put_Line( '--Entity:'||l_entity );

        -- Based on entity - get log table and recordset
            change_table := getchangelogtables(ientitytype=> l_entity);
            DBMS_OUTPUT.Put_Line( '--Log table:'||change_table );

        -- ToDO
        -- mltJurisdiction
        -- mltTaxes
        -- mltTaxability
    end;
    */




    PROCEDURE update_multiple_log(p_process_id in number, p_ref OUT SYS_REFCURSOR) IS
        upd_primary_key NUMBER;       -- change log primary key
        l_entity        NUMBER;       --
        l_change_table  VARCHAR2(32); -- change log table

        sq_Doc   CLOB := ' LEFT JOIN <cit_log> cc ON (cc.<chg_log_id> = clo.id)
                           LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                           LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
        sq_Verif CLOB := ' LEFT JOIN <vld_table> cva ON (cva.<chg_log_id> = clo.id)
                           LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
        addgroupStmt CLOB;

        -- Either fixed set of queries by entity or lookup column table
        -- display columns (default out record layout)
        dsp_columns CLOB := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED,
                                    COL_BY, COL_REASON, COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME, REFERENCE_CODE, table_name,
                                    <pEntity> SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                    , jurisdiction_rid jurisdictions_rid
                                    , juris_tax_imposition_rid juris_tax_impositions_rid
                                    , jurisdiction_nkid
                             FROM ( ';
        form_columns CLOB;
    BEGIN
        DBMS_OUTPUT.Put_Line('Process id:'||p_process_id);
        -- , wm_concat(distinct atc.id) COL_DOC_ID_LIST    -- Changed to LISTAGG - CRAPP-2516

        sq_Main := 'SELECT DISTINCT
                           clo.id change_logId
                           , clo.rid COL_RID
                           , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                  WHEN clo.status = 1 THEN ''Locked''
                                  ELSE ''Pending''
                             END COL_PUBLISHED
                           , clo.entered_date COL_MODIFIED
                           , usr.firstname ||  '' '' ||usr.lastname COL_BY
                           , cr.reason COL_REASON
                           , regexp_replace(LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                     WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
                                     ,''([^,]+)(, \1)+'', ''\1'')
                                     AS COL_VERIFIED_BY
                           , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                           , <replace_jname> COL_JNAME
                           , <replace_refcode> REFERENCE_CODE
                           , etm.ui_alias||'': ''||q.qr table_name
                           , ar.nkid COL_NKID
                           , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                           , <replace_rid> jurisdiction_rid
                           , <replace_imprid> juris_tax_imposition_rid
                           , <replace_nkid> jurisdiction_nkid
                    FROM <replace_chg> clo
                         JOIN entity_table_map etm on (etm.table_name = clo.table_name)
                         JOIN <qr_table> q on (q.table_name = etm.table_name and q.ref_id = clo.primary_key)
                         -- Entity
                         AND etm.logical_entity = ''<replace_ent_name>''
                         -- base data
                         JOIN <replace_revisiontable> rv ON (rv.id = clo.rid)
                         JOIN <replace_ent_main> ar ON (rv.nkid = ar.nkid AND rev_join(ar.rid,rv.id,ar.next_rid) = 1) ';

        -- q&d get the log table name
        DBMS_OUTPUT.Put_Line( 'Entity' );

        SELECT log_table, entity
        INTO l_change_table, l_entity
        FROM change_log_table_lookup
        WHERE entity = (SELECT DISTINCT entity
                        FROM update_multiple_log where process_id=p_process_id);

        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED,
                                to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, <COL_JNAME>, REFERENCE_CODE,
                                table_name, <replace_section> SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
                         FROM ( ';

        -- alt. USING
        form_columns := REPLACE(form_columns,'<replace_section>',l_entity);

        -- 1. Admin
        if l_entity = 1 then
            form_columns := REPLACE(form_columns,'<COL_JNAME>','COL_ADMINISTRATOR');
            addgroupStmt := ',clo.status
                             ,clo.rid
                             ,ar.name
                             ,ar.nkid
                             ,atc.id
                             ,cva.assigned_user_id ';
        end if;

        -- 2. Jurisdiction
        if l_entity = 2 then
            form_columns := REPLACE(form_columns,'<COL_JNAME>','COL_JNAME');

            sq_main := REPLACE(sq_main,'<replace_refcode>',''' ''');
            sq_main := REPLACE(sq_main,'<replace_rid>',''' ''');
            sq_main := REPLACE(sq_main,'<replace_imprid>',''' ''');
            sq_main := REPLACE(sq_main,'<replace_nkid>',''' ''');
            sq_main := REPLACE(sq_main,'<replace_ent_name>','Jurisdiction');
            sq_main := REPLACE(sq_main,'<replace_revisiontable>','jurisdiction_revisions');
            sq_main := REPLACE(sq_main,'<replace_chg>',l_change_table);
            sq_main := REPLACE(sq_main,'<replace_ent_main>','jurisdictions');
            sq_main := REPLACE(sq_main,'<replace_jname>','ar.official_name');
            sq_main := REPLACE(sq_main,'<qr_table>','juris_qr');

            sq_Doc := REPLACE(sq_Doc,'<cit_log>','juris_chg_cits');
            sq_Doc := REPLACE(sq_Doc,'<chg_log_id>','juris_chg_log_id');

            sq_Verif := REPLACE(sq_Verif,'<vld_table>','juris_chg_vlds');
            sq_Verif := REPLACE(sq_Verif,'<chg_log_id>','juris_chg_log_id');

            addgroupStmt := ',clo.status
                             ,clo.rid
                             ,ar.official_name
                             ,ar.nkid
                             ,atc.id
                             ,cva.assigned_user_id ';
        end if;

        -- 3. Taxes
        if l_entity = 3 then
            form_columns := REPLACE(form_columns,'<COL_JNAME>','COL_JNAME');

            sq_main := sq_main || 'JOIN jurisdictions jr ON (jr.id = ar.jurisdiction_id) ';
            sq_main := REPLACE(sq_main,'<replace_refcode>','ar.reference_code');
            sq_main := REPLACE(sq_main,'<replace_rid>','jr.rid');
            sq_main := REPLACE(sq_main,'<replace_imprid>','clo.rid');
            sq_main := REPLACE(sq_main,'<replace_nkid>','jr.nkid');
            sq_main := REPLACE(sq_main,'<replace_ent_name>','Tax');
            sq_main := REPLACE(sq_main,'<replace_revisiontable>','jurisdiction_tax_revisions');
            sq_main := REPLACE(sq_main,'<replace_chg>',l_change_table);
            sq_main := REPLACE(sq_main,'<replace_ent_main>','juris_tax_impositions');
            sq_main := REPLACE(sq_main,'<replace_jname>','jr.official_name');
            sq_main := REPLACE(sq_main,'<qr_table>','tax_qr');

            sq_Doc := REPLACE(sq_Doc,'<cit_log>','juris_tax_chg_cits');
            sq_Doc := REPLACE(sq_Doc,'<chg_log_id>','juris_tax_chg_log_id');

            sq_Verif := REPLACE(sq_Verif,'<vld_table>','juris_tax_chg_vlds');
            sq_Verif := REPLACE(sq_Verif,'<chg_log_id>','juris_tax_chg_log_id');

            addgroupStmt := ',clo.status
                             ,clo.rid
                             ,jr.official_name
                             ,ar.reference_code
                             ,ar.nkid
                             ,ar.rid
                             ,jr.rid
                             ,jr.nkid
                             ,atc.id
                             ,cva.assigned_user_id ';
        end if;

        -- 4. Taxability
        if l_entity = 4 then
            form_columns := REPLACE(form_columns,'<COL_JNAME>','COL_JNAME');

            sq_main := sq_main || 'JOIN jurisdictions jr ON (jr.id = ar.jurisdiction_id) ';
            sq_main := REPLACE(sq_main,'<replace_refcode>','ar.reference_code');
            sq_main := REPLACE(sq_main,'<replace_rid>','jr.rid');
            sq_main := REPLACE(sq_main,'<replace_imprid>','clo.rid');
            sq_main := REPLACE(sq_main,'<replace_nkid>','jr.nkid');
            sq_main := REPLACE(sq_main,'<replace_ent_name>','Taxability');
            sq_main := REPLACE(sq_main,'<replace_revisiontable>','juris_tax_app_revision');
            sq_main := REPLACE(sq_main,'<replace_chg>',l_change_table);
            sq_main := REPLACE(sq_main,'<replace_ent_main>','juris_tax_applicabilities');    -- Added CR2 to tablename - CRAPP-2516
            sq_main := REPLACE(sq_main,'<replace_jname>','jr.official_name');
            sq_main := REPLACE(sq_main,'<qr_table>','juris_tax_app_qr');

            sq_Doc := REPLACE(sq_Doc,'<cit_log>','juris_tax_app_chg_cits');
            sq_Doc := REPLACE(sq_Doc,'<chg_log_id>','juris_tax_app_chg_log_id');

            sq_Verif := REPLACE(sq_Verif,'<vld_table>','juris_tax_app_chg_vlds');
            sq_Verif := REPLACE(sq_Verif,'<chg_log_id>','juris_tax_app_chg_log_id');

            addgroupStmt := ',clo.status
                             ,clo.rid
                             ,jr.official_name
                             ,jr.rid
                             ,jr.nkid
                             ,ar.rid
                             ,ar.reference_code
                             ,ar.nkid
                             ,atc.id
                             ,cva.assigned_user_id ';
        end if;

        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Verif;
        sq_whr := 'WHERE exists
                            (select 1 from update_multiple_log ul
                             where clo.primary_key = ul.primary_key
                                   and process_id = :process_id
                            ) ';
        --and ul.status=2

        sq_entity := sq_entity || sq_whr;
        sq_Entity := sq_Entity || grpBy_Default || addgroupStmt;

        form_columns := form_columns || sq_entity ||')';

        DBMS_OUTPUT.Put_Line( form_columns );

        OPEN p_ref FOR form_columns USING p_process_id;
    END update_multiple_log;


    ------------------------------------------------------------------------------
    -- Copy tax log / Change log
    --
    PROCEDURE copy_tax_log(p_process_id in number, p_ref OUT SYS_REFCURSOR) IS
        upd_primary_key NUMBER;       -- change log primary key
        l_entity        NUMBER;       --
        l_change_table  VARCHAR2(32); -- change log table

        sq_Doc   CLOB := ' LEFT JOIN <cit_log> cc ON (cc.<chg_log_id> = clo.id)
                           LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                           LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
        sq_Verif CLOB := ' LEFT JOIN <vld_table> cva ON (cva.<chg_log_id> = clo.id)
                           LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
		-- sq_tags added as part of CRAPP-2236
		sq_Tags CLOB := ' LEFT OUTER JOIN jurisdiction_tags juristgs on (juristgs.ref_nkid = jr.nkid)
                          LEFT OUTER JOIN Tags tgs ON (tgs.id = juristgs.tag_id) ';
        addgroupStmt CLOB;

        -- Either fixed set of queries by entity or lookup column table
        -- display columns (default out record layout)
        dsp_columns CLOB := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:mi:ss'') COL_MODIFIED,
                                    COL_BY, COL_REASON, COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME, REFERENCE_CODE, table_name,
                                    <pEntity> SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                    , jurisdiction_rid jurisdictions_rid
                                    , juris_tax_imposition_rid juris_tax_impositions_rid
                                    , jurisdiction_nkid
                             FROM ( ';
        form_columns CLOB;
    BEGIN
        DBMS_OUTPUT.Put_Line('Process id:'||p_process_id);
        -- , wm_concat(distinct atc.id) COL_DOC_ID_LIST    -- Changed to LISTAGG - CRAPP-2516

        sq_Main := 'SELECT DISTINCT
                           clo.id change_logId
                           , clo.rid COL_RID
                           , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                  WHEN clo.status = 1 THEN ''Locked''
                                  ELSE ''Pending''
                             END COL_PUBLISHED
                           , clo.entered_date COL_MODIFIED
                           , usr.firstname ||  '' '' ||usr.lastname COL_BY
                           , cr.reason COL_REASON
                           , regexp_replace(LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                     WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id)
                                     ,''([^,]+)(, \1)+'', ''\1'')
                                     AS COL_VERIFIED_BY
                           , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                           , <replace_jname> COL_JNAME
                           , <replace_refcode> REFERENCE_CODE
                           , etm.ui_alias||'': ''||q.qr table_name
                           , ar.nkid COL_NKID
                           , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                           , <replace_rid> jurisdiction_rid
                           , <replace_imprid> juris_tax_imposition_rid
                           , <replace_nkid> jurisdiction_nkid
						   , regexp_replace(LISTAGG(tgs.name, '','') WITHIN GROUP (ORDER BY tgs.id) over (PARTITION BY clo.id),''([^,]+)(,\1)+'', ''\1'') TAG_NAME
                    FROM <replace_chg> clo
                         JOIN entity_table_map etm on (etm.table_name = clo.table_name)
                         JOIN <qr_table> q on (q.table_name = etm.table_name and q.ref_id = clo.primary_key)
                         -- Entity
                         AND etm.logical_entity = ''<replace_ent_name>''
                         -- base data
                         JOIN <replace_revisiontable> rv ON (rv.id = clo.rid)
                         JOIN <replace_ent_main> ar ON (rv.nkid = ar.nkid AND rev_join(ar.rid,rv.id,ar.next_rid) = 1) ';

        -- q&d get the log table name
        -- (The l_entity is always 3 for now since we don't have taxability log yet)
        DBMS_OUTPUT.Put_Line( 'Entity' );

        SELECT log_table, entity
        INTO l_change_table, l_entity
        FROM change_log_table_lookup
        WHERE entity = 3;
		-- column tag_name included in below statement as part of CRAPP-2236
        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED,
                                to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, <COL_JNAME>, REFERENCE_CODE,
                                table_name, <replace_section> SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
								,tag_name
                         FROM ( ';

        -- alt. USING
        form_columns := REPLACE(form_columns,'<replace_section>',l_entity);

        -- 3. Taxes
        if l_entity = 3 then
            form_columns := REPLACE(form_columns,'<COL_JNAME>','COL_JNAME');

            sq_main := sq_main || 'JOIN jurisdictions jr ON (jr.id = ar.jurisdiction_id) ';
            sq_main := REPLACE(sq_main,'<replace_refcode>','ar.reference_code');
            sq_main := REPLACE(sq_main,'<replace_rid>','jr.rid');
            sq_main := REPLACE(sq_main,'<replace_imprid>','clo.rid');
            sq_main := REPLACE(sq_main,'<replace_nkid>','jr.nkid');
            sq_main := REPLACE(sq_main,'<replace_ent_name>','Tax');
            sq_main := REPLACE(sq_main,'<replace_revisiontable>','jurisdiction_tax_revisions');
            sq_main := REPLACE(sq_main,'<replace_chg>',l_change_table);
            sq_main := REPLACE(sq_main,'<replace_ent_main>','juris_tax_impositions');
            sq_main := REPLACE(sq_main,'<replace_jname>','jr.official_name');
            sq_main := REPLACE(sq_main,'<qr_table>','tax_qr');

            sq_Doc := REPLACE(sq_Doc,'<cit_log>','juris_tax_chg_cits');
            sq_Doc := REPLACE(sq_Doc,'<chg_log_id>','juris_tax_chg_log_id');

            sq_Verif := REPLACE(sq_Verif,'<vld_table>','juris_tax_chg_vlds');
            sq_Verif := REPLACE(sq_Verif,'<chg_log_id>','juris_tax_chg_log_id');

            addgroupStmt := ',clo.status
                             ,clo.rid
                             ,jr.official_name
                             ,ar.reference_code
                             ,ar.nkid
                             ,ar.rid
                             ,jr.rid
                             ,jr.nkid
                             ,atc.id
                             ,cva.assigned_user_id
							 ,tgs.name, tgs.id ';
        end if;

        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Tags || sq_Verif;
        sq_whr := 'WHERE exists
                            (select 1 from tax_copy_log ul
                             where clo.rid = ul.juris_imp_rid
                                   and log_id = :process_id and ul.cpy_status=1)';

        sq_entity := sq_entity || sq_whr;
        sq_Entity := sq_Entity || grpBy_Default || addgroupStmt;

        form_columns := form_columns || sq_entity ||')';
        DBMS_OUTPUT.Put_Line( form_columns );

        OPEN p_ref FOR form_columns USING p_process_id;
    end copy_tax_log;




    -- MULTI_SEARCHLOG
    --
    --
    FUNCTION multi_searchLog(p_process_id IN NUMBER) RETURN outTable PIPELINED IS
        dataRecord outSet;
        cursor_ml SYS_REFCURSOR;
        l_process_id number;
        l_cpy_type number;
    begin
        -- Check what log we're working with here
        select distinct proc_id, cpy_type into l_process_id, l_cpy_type
        from
            (select process_id proc_id,1 cpy_type, eid lk_id, primary_key p_key
             FROM update_multiple_log
             UNION ALL
             select log_id proc_id, 2 cpy_type, juris_imp_rid lk_id, cpy_rid p_key
             from tax_copy_log
             where cpy_section = 1
            )
        where proc_id=p_process_id;

        -- Pipe copy tax change log back using the same cursor
        if l_cpy_type = 2 then
            copy_tax_log(p_process_id, cursor_ml);
        end if;

        -- 6/8 note: this was part of the older code - we'll leave it here for now
        if l_cpy_type = 1 then
            update_multiple_log(p_process_id, cursor_ml);
        end if;

        IF cursor_ml%ISOPEN THEN
            LOOP
                FETCH cursor_ml INTO dataRecord;
                EXIT WHEN cursor_ml%NOTFOUND;
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_ml;
        END IF;
    end multi_searchlog;




    /*    -- Removed - CRAPP-2516
    procedure comm_group_logSQL(p_process_id in number, p_ref OUT SYS_REFCURSOR)
    is
        primary_key    number;       -- change log primary key
        l_entity       number;       --
        l_change_table varchar2(32); -- change log table

        sq_Doc   CLOB := ' LEFT JOIN <cit_log> cc ON (cc.<chg_log_id> = clo.id)
                           LEFT JOIN citations ci ON (cc.citation_id = ci.id)
                           LEFT JOIN attachments atc ON (atc.id = ci.attachment_id) ';
        sq_Verif CLOB := ' LEFT JOIN <vld_table> cva ON (cva.<chg_log_id> = clo.id)
                           LEFT JOIN assignment_types ast ON (ast.id = cva.assignment_type_id) ';
        addgroupStmt CLOB;

        -- Either fixed set of queries by entity or lookup column table
        -- display columns (default out record layout)
        dsp_columns CLOB := 'Select CHANGE_LOGID, COL_RID, COL_PUBLISHED, to_char(COL_MODIFIED,''mm/dd/yyyy HH24:mi:ss'') COL_MODIFIED,
                                    COL_BY, COL_REASON, COL_VERIFIED_BY, COL_DOCUMENTS, COL_JNAME, REFERENCE_CODE, table_name,
                                    <pEntity> SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                    , jurisdiction_rid jurisdictions_rid
                                    , juris_tax_imposition_rid juris_tax_impositions_rid
                                    , jurisdiction_nkid From (';
        form_columns CLOB;
    begin
        DBMS_OUTPUT.Put_Line('Process id:'||p_process_id);

        sq_Main := 'SELECT DISTINCT
                           clo.id change_logId
                           , clo.rid COL_RID
                           , CASE WHEN clo.status = 2 THEN to_char(clo.status_modified_date,''mm/dd/yyyy'')
                                  WHEN clo.status = 1 THEN ''Locked''
                                  ELSE ''Pending'' END COL_PUBLISHED
                           , clo.entered_date COL_MODIFIED
                           , usr.firstname ||  '' '' ||usr.lastname COL_BY
                           , cr.reason COL_REASON
                           , LISTAGG(fnAssignmentAbbr(ast.id)||'' ''|| get_username(cva.assigned_user_id), '''||colDelim||''')
                                     WITHIN GROUP (ORDER BY ast.id) over (PARTITION BY clo.id) AS COL_VERIFIED_BY
                           , nvl(count(distinct ci.attachment_id),0) COL_DOCUMENTS
                           , <replace_jname> COL_JNAME
                           , <replace_refcode> REFERENCE_CODE
                           , etm.ui_alias||'': ''||q.qr table_name
                           , ar.nkid COL_NKID
                           , LISTAGG(atc.id, '','') WITHIN GROUP (ORDER BY atc.id) over (PARTITION BY clo.id) COL_DOC_ID_LIST
                           , <replace_rid> jurisdiction_rid
                           , <replace_imprid> juris_tax_imposition_rid
                           , <replace_nkid> jurisdiction_nkid
                    FROM <replace_chg> clo
                         JOIN entity_table_map etm on (etm.table_name = clo.table_name)
                         JOIN <qr_table> q on (q.table_name = etm.table_name and q.ref_id = clo.primary_key)
                         -- Entity
                         AND etm.logical_entity = ''<replace_ent_name>''
                         -- base data
                         JOIN <replace_revisiontable> rv ON (rv.id = clo.rid)
                         JOIN <replace_ent_main> ar ON (rv.nkid = ar.nkid AND rev_join(ar.rid,rv.id,ar.next_rid) = 1) ';

        -- q&d get the log table name
        DBMS_OUTPUT.Put_Line( 'Entity' );
        Select log_table, entity
        into l_change_table, l_entity
        From change_log_table_lookup
        Where entity = 6;

        form_columns := 'SELECT CHANGE_LOGID, COL_RID, COL_PUBLISHED,
                                to_char(COL_MODIFIED,''mm/dd/yyyy HH24:MI:SS'') COL_MODIFIED, COL_BY, COL_REASON,
                                COL_VERIFIED_BY, COL_DOCUMENTS, <COL_JNAME>, REFERENCE_CODE,
                                table_name, <replace_section> SECTION_ID, COL_NKID, COL_DOC_ID_LIST
                                , jurisdiction_rid jurisdictions_rid
                                , juris_tax_imposition_rid juris_tax_impositions_rid
                                , jurisdiction_nkid
                         FROM (';

        form_columns := REPLACE(form_columns,'<replace_section>',l_entity);

        -- 6. commodity groups
        if l_entity = 6 then
            form_columns:=REPLACE(form_columns,'<COL_JNAME>','COL_JNAME');

            sq_main := REPLACE(sq_main,'<replace_refcode>',''' ''');
            sq_main := REPLACE(sq_main,'<replace_rid>',''' ''');
            sq_main := REPLACE(sq_main,'<replace_imprid>',''' ''');
            sq_main := REPLACE(sq_main,'<replace_nkid>',''' ''');
            sq_main := REPLACE(sq_main,'<replace_ent_name>','Commodity Group');
            sq_main := REPLACE(sq_main,'<replace_revisiontable>','commodity_group_revisions');
            sq_main := REPLACE(sq_main,'<replace_chg>',l_change_table);
            sq_main := REPLACE(sq_main,'<replace_ent_main>','Commodity_Groups');
            sq_main := REPLACE(sq_main,'<replace_jname>','ar.name');
            sq_main := REPLACE(sq_main,'<qr_table>','comm_grp_qr');

            sq_Doc := REPLACE(sq_Doc,'<cit_log>','comm_grp_chg_cits');
            sq_Doc := REPLACE(sq_Doc,'<chg_log_id>','comm_grp_chg_log_id');

            sq_Verif := REPLACE(sq_Verif,'<vld_table>','comm_grp_chg_vlds');
            sq_Verif := REPLACE(sq_Verif,'<chg_log_id>','comm_grp_chg_log_id');

            addgroupStmt := ',clo.status
                             ,clo.rid
                             ,ar.name
                             ,ar.nkid
                             ,atc.id
                             ,cva.assigned_user_id ';
        end if;

        sq_entity := sq_Main || sq_UserSet || sq_reason || sq_Doc || sq_Verif;
        sq_whr := 'WHERE exists
                    (select 1 from comm_grp_added_comm_log ul
                     where clo.primary_key = ul.comm_grp_id
                           and id = :process_id)';

        sq_entity := sq_entity|| sq_whr;
        sq_Entity := sq_Entity|| grpBy_Default || addgroupStmt;

        form_columns := form_columns||sq_entity||')';

        DBMS_OUTPUT.Put_Line( form_columns );
        OPEN p_ref FOR form_columns USING p_process_id;
    end comm_group_logSQL;


    FUNCTION comm_group_searchLog(p_process_id IN NUMBER) RETURN outTable PIPELINED IS
        dataRecord outSet;
        cursor_ml SYS_REFCURSOR;
        l_process_id number;
        l_cpy_type number;
    begin
        comm_group_logsql(p_process_id, cursor_ml);

        IF cursor_ml%ISOPEN THEN
            LOOP
                FETCH cursor_ml INTO dataRecord;
                EXIT WHEN cursor_ml%NOTFOUND;
                PIPE row(dataRecord);
            END LOOP;
            CLOSE cursor_ml;
        END IF;
    end comm_group_searchLog;
    */

END changelog_search;
/