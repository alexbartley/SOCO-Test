CREATE OR REPLACE PACKAGE BODY content_repo."UPDATE_MULTIPLE"
IS
-- *****************************************************************
-- Description:
--
-- Input Parameters: nil
--
-- Output Parameters: nil
--
-- Error Conditions Raised: nil
--
-- Revision History
-- Date            Author       Reason for Change
-- ----------------------------------------------------------------
-- 11 OCT 2014     TNN          Raw script created
-- 14 OCT 2014     TNN          MidTier tags missing/ name change
-- 11 AUG 2015     TNN          jun/july fixes and cleanup
-- *****************************************************************
-- Suggested ToDo: Move each entity section to its own procedure
-- Suggested ToDo: function for xml jurisdiction id split

/******************************************************************************/
/* CRETAB Section
/*
/* lookup table
/*
/*  Create Table update_multiple_sections
/*  (id number
/*   unique constraint update_multiple_sections_pk not null,
/*   description varchar2(64),
/*   entity number);
/*
/*
/* Default data for possible sections to update
/*
  insert all
  into update_multiple_sections values(1,'Jurisdiction Tax Description',2)
  into update_multiple_sections values(2,'Jurisdiction Attributes',2)
  into update_multiple_sections values(3,'Jurisdiction Tags',2)
  into update_multiple_sections values(4,'Tax Definitions',3)
  into update_multiple_sections values(5,'Tax Reporting Codes',3)
  into update_multiple_sections values(6,'Tax Administrators',3)
  into update_multiple_sections values(7,'Tax Additional Attributes',3)
  into update_multiple_sections values(8,'Tax Tags',3)
  select * from dual;
*/
-- Sequence for process number
/*
  Create Sequence update_multiple_process_sq start with 100;
*/

    Type UM_Record_Status is record
    (
      N_REC_IN number,
      N_QUEUE number,
      N_PROCESSED number,
      N_FAILED number
    );
    Type UM_Record_Table is Table Of UM_Record_Status;
    UM_Records_DS UM_Record_Table := UM_Record_Table();

    -- Tax description
    type UM_Juris_TaxDescr is record
    (
     crud number,
     taxation_id NUMBER,
     spec_app_id number,
     trans_id number,
     tax_descr number,
     start_date varchar2(11),
     end_date varchar2(11)
     , jl varchar2(4000) -- jurisdiction_id list
     , entered_by number
    );
    TYPE T_Juris_Table IS TABLE OF UM_Juris_TaxDescr;
    r_T_Juris T_Juris_Table:=T_Juris_Table();

    -- Attributes
    type UM_Juris_Attrib is record
    (
      crud number,
      value varchar2(500),
      attribute_id number,
      attribute_category_id number,
      start_date varchar2(11),
      end_date varchar2(11),
      jl varchar2(4000),
      entered_by number
    );
    TYPE T_Juris_Attrib IS TABLE OF UM_Juris_Attrib;
    r_T_Juris_Attrib T_Juris_Attrib:=T_Juris_Attrib();

    -- Jurisdiction tags
    type UM_Juris_Tags is record
    (
      crud number,
      tag_id number,
      jl varchar2(4000),
      entered_by number
    );
    TYPE T_Juris_Tags IS TABLE OF UM_Juris_Tags;
    r_T_Juris_Tags T_Juris_Tags:=T_Juris_Tags();    -- Local tag record dataset

    -- Tax Definitions
    type UM_Tax_Definition is record
    (
      crud number,
      start_date varchar2(11),
      end_date varchar2(11),
      calculation_structure_id number,
      tax_structure_type_id number,
      tax_imposition_ids clob,
      entered_by number,
      min_threshold number,
      max_limit number,
      value number,
      value_type varchar2(15),
      currency_id number,
      ref_juris_tax_id varchar2(12)
    );
    Type T_Tax_Defn is table of UM_Tax_Definition;
    r_T_Tax_Defn T_Tax_Defn:=T_Tax_Defn();

    -- Tax Reporting Codes
    Type UM_Tax_Report is record
    (
      crud number,
      value varchar2(256),
      attribute_id number,
      start_date varchar2(11),
      end_date varchar2(11),
      jl varchar2(4000),
      entered_by number
    );
    TYPE T_Tax_Report IS TABLE OF UM_Tax_Report;
    r_T_Tax_Report T_Tax_Report:=T_Tax_Report();

    -- Tax Administrators
    Type UM_Tax_Admin is record
    (
      crud number,
      admin_id number,
      administrator_name varchar2(512),
      collects_tax number,
      collector_id number,
      start_date varchar2(11),
      end_date varchar2(11),
      jl varchar2(4000),
      entered_by number
    );
    TYPE T_Tax_Admin IS TABLE OF UM_Tax_Admin;
    r_T_Tax_Admin T_Tax_Admin:=T_Tax_Admin();

    -- Tax Additional Attributes
    type UM_Tax_Attrib is record
    (
      crud number,
      value varchar2(500),
      attribute_id number,
      attribute_category_id number,
      start_date varchar2(11),
      end_date varchar2(11),
      jl varchar2(4000),
      entered_by number
    );
    TYPE T_Tax_Attrib IS TABLE OF UM_Tax_Attrib;
    r_T_Tax_Attrib T_Tax_Attrib:=T_Tax_Attrib();

    -- Tax Tags
    type UM_Tax_Tags is record
    (
      crud number,
      tag_id number,
      jl varchar2(4000),
      entered_by number
    );
    TYPE T_Tax_Tags IS TABLE OF UM_Tax_Tags;
    r_T_Tax_Tags T_Tax_Tags:=T_Tax_Tags();    -- Local Tax tag record dataset


    -- Generic Tag List (used by all entities locally)
    tag_list xmlform_tags_tt := xmlform_tags_tt();  -- SCHEMA TYPE

    Type tt_juris_id is table of jurisdictions.id%type;
    Type tt_tax_id is table of juris_tax_impositions.id%type;
    Type tt_taxab_id is table of juris_tax_applicabilities.id%type;
    juris_id_tbl tt_juris_id:=tt_juris_id();

    -- Handle id clob getClobVal (varchar)
    Type id_tt is table of varchar2(16);
    id_rs id_tt:=id_tt();
    id_reccount number:=0;


    l_td_id number;        -- lookup tax description id (or new)
    l_td_pk number:=null;  -- juris tax description pk
    l_att_id number;       -- lookup attribute id (or new)
    l_att_pk number:=null; -- jurisdiction_attributes id

    rTaxDescrDelete number:=1;  -- Tax description return
    rJurisAttribDelete number;
    rReportingCodeDelete number;
    pDelete number:=0;
    rTaxDefnDelete number;

    -- Return # of failed records
    Function umLogStat(ProcessID in number) return number
    is
    begin
        Select
        sum(decode(status,0,1,0)) N_REC_IN,
        sum(decode(status,1,1,0)) N_QUEUE,
        sum(decode(status,2,1,0)) N_PROCESSED,
        sum(decode(status,-1,1,0)) N_FAILED
        Bulk collect into UM_Records_DS
        From update_multiple_log
        Where process_id=process_id;
        Return UM_Records_DS(1).N_FAILED;
    end;

    -- Return a list of failed Id's
    Function umLogReturn(ProcessId in number) return varchar2
    is
        l_type number;
    begin
      -- simple lookup
      Select max(lg.entity)
      into l_type
      from update_multiple_log lg
      where lg.process_id = ProcessId;
     Return null;
    end;

/* This is the function you are looking for...
   Referenced. Might need to add NEXT_RID or join to Revision table to get the latest

a) IF you are expecting not to find data for some rows AND this is OK, catch
the no_data_found and set default values for the into variables
b) IF you are NOT expecting "no data found" don't use an exception block at all
-- this is an error, it must be propagated up and out of your code to the caller --
just like an "out of space" error on an insert would be.
Ultimately the reference_code and id must exist.
*/
    function getJurisImpRefId(i_jti_id in number, ref_code in varchar2) return number
    is
      jti_id juris_tax_impositions.id%type;
    begin
    DBMS_OUTPUT.Put_Line( i_jti_id||' '||ref_code );
      if ref_code is null then
        return null;
      else
        begin
        select imp.id into jti_id
        from juris_tax_impositions imp
        where exists (select 1
        from juris_tax_impositions jti
             where jti.jurisdiction_nkid = imp.jurisdiction_nkid
             -- this was the orig id
             and jti.id=i_jti_id)
        and imp.reference_code=ref_code;
        exception when no_data_found then
          jti_id:=-1;
        end;
        return jti_id;
      end if;
    end;

    /* TAX Definitions */
    -- Mimic TaxLaw_Taxes package (tags are different, return values are different)
  FUNCTION XMLForm_TaxesDefinition(form_xml_i IN SYS.XMLType)
  RETURN XMLForm_TaxDefn_TT PIPELINED IS
    out_rec            XMLForm_TaxesDefine; -- Header section
    poxml              sys.XMLType;
    i                  binary_integer := 1;
    l_form_xml         sys.XMLType := form_xml_i;
    l_end_date         sys.XMLType;
    l_start_date       sys.XMLType;
    l_description      sys.XMLType;
    l_referencecodetxt sys.XMLType;
    chkMeStr           sys.XMLType;
  BEGIN
    -- init based on required number of fields in XMLForm_TaxesDefine
   out_rec := XMLForm_TaxesDefine(NULL, NULL, NULL, NULL, NULL, NULL, NULL,
   NULL, NULL, NULL, NULL, NULL, NULL, NULL);
   LOOP
    poxml := l_form_xml.extract('jurisdictiontaxes['||i||']');
    EXIT WHEN poxml IS NULL;
    SELECT
        h.id,
        h.rid,
        h.nkid,
        h.jurisdiction_id,
        h.tax_description_id,
        h.modified,
        h.deleted,
        h.revenue_purpose_id,
        h.entered_by,
        to_date(h.start_date),
        to_date(h.end_date),
        h.description,
        h.reference_code
      INTO
        out_rec.id,
        out_rec.rid,
        out_rec.nkid,
        out_rec.jurisdiction_id,
        out_rec.taxdescriptionid,
        out_rec.modified,
        out_rec.deleted,
        out_rec.revenuepurpose,
        out_rec.enteredby,
        out_rec.startdate,
        out_rec.enddate,
        out_rec.description,
        out_rec.referencecode
      FROM XMLTABLE (
      '/tax_upd_multiple'
      PASSING poxml
                        COLUMNS id   NUMBER PATH 'id', -- blank
                                rid   NUMBER PATH 'rid', -- blank
                                nkid   NUMBER PATH 'nkid', -- blank
                                jurisdiction_id  NUMBER PATH 'jurisdiction_id',
                                tax_description_id NUMBER PATH 'tax_description_id',
                                modified NUMBER PATH 'modified',
                                deleted   NUMBER PATH 'deleted',
                                revenue_purpose_id number PATH 'revenue_purpose_id',
                                entered_by NUMBER path 'entered_by',
                                start_date varchar2(12) path 'start_date',
                                end_date varchar2(12) path 'end_date',
                                description varchar2(250) path 'description',
                                reference_code varchar2(50) path 'reference_code'
                                ) h;
    PIPE ROW(out_rec);
    i := i + 1;
    END LOOP;
    RETURN;
  END XMLForm_TaxesDefinition;

  /* -------------------------------------------------------------------------
   * JURISDICTION Tax Categories
   * Eqv. in Jurisdiction package except for error/stop logging
   * --> ALT. Overloaded procedure in Jurisdiction package
  */
  PROCEDURE remove_tax_description (
              id_i IN NUMBER,
              deleted_by_i IN NUMBER,
              jurisdiction_id_i IN number,
              pDelete OUT number
    )
    IS
        l_juris_tax_desc_id NUMBER := id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_juris_id NUMBER := jurisdiction_id_i;
        l_tax_desc_id NUMBER;
        l_rid NUMBER;
        l_nkid NUMBER;
        l_rec_count number;
    BEGIN
        pDelete:=0;

        -- steps check 1
        select tax_description_id into l_tax_desc_id from juris_tax_descriptions
        where id=l_juris_tax_desc_id;

        -- steps check 2
        Select count(*) into l_rec_count
        from jurisdictions jr
        where exists
        (select 1 from juris_tax_impositions jti
         where jti.tax_description_id=l_tax_desc_id
         and jti.jurisdiction_id=jr.id)
         and jr.id=l_juris_id;

        DBMS_OUTPUT.Put_Line( 'Taxes linked:'||l_rec_count );

        -- no taxes yet linked to this juris/tax descr combination
        if l_rec_count = 0 then
          INSERT INTO tmp_delete(table_name, primary_key) VALUES ('JURIS_TAX_DESCRIPTIONS',l_juris_tax_desc_id);

          DELETE FROM juris_tax_descriptions jtd
          WHERE jtd.id = l_juris_tax_desc_id
          RETURNING rid, nkid INTO l_rid, l_nkid;

          INSERT INTO delete_logs (table_name, primary_key, deleted_by)
          VALUES ('JURIS_TAX_DESCRIPTIONS',l_juris_tax_desc_id , l_deleted_by);

          UPDATE juris_tax_descriptions jtd
          SET next_Rid = NULL
          WHERE jtd.next_rid = l_rid
          AND jtd.nkid = l_nkid;
          pDelete := 1;
        else
          -- RAISE errnums.cannot_delete_record;
          -- ToDo: Log here might be a good idea
          -- UM_Log(l_juris_id, l_tax_desc_id, 0 {No can do}, sysdate);
          pDelete := 0;
        end if;

        EXCEPTION
            WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_i);
  END remove_tax_description;


  /** JURISDICTION Remove Attributes
   *
   */
  PROCEDURE remove_attribute (
      id_i IN NUMBER,
      deleted_by_i IN NUMBER,
      pDelete OUT number
    )
    IS
        l_juris_att_id NUMBER := id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_juris_id NUMBER;
        l_attrib_id NUMBER;
        l_rid NUMBER;
        l_nkid NUMBER;
        l_rec_count number;
  BEGIN
        pDelete:=0;

        -- step check
        Select count(*) into l_rec_count
        from jurisdiction_attributes ja
        where ja.id=id_i;

    if l_rec_count = 1 then

    INSERT INTO tmp_delete(table_name, primary_key) VALUES ('JURISDICTION_ATTRIBUTES', l_juris_att_id);

    DELETE FROM jurisdiction_attributes ja
     WHERE ja.id = l_juris_att_id
     AND ja.status=0
    RETURNING rid, nkid INTO l_rid, l_nkid;
    INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
    SELECT table_name, primary_key, l_deleted_by
      FROM tmp_delete
    );

    UPDATE jurisdiction_attributes jta
    SET next_Rid = NULL
    WHERE jta.next_rid = l_rid
      AND jta.nkid = l_nkid;
          pDelete := 1;
    else
          -- ToDo: Log here or in main procedure?
          -- UM_Log(l_juris_id, l_tax_desc_id, 0 {No can do}, sysdate);
          pDelete := 0;
    end if;
    EXCEPTION
         WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_i);
  END remove_attribute;


  /** Remove Tax Attributes
   *
   */
  PROCEDURE remove_tax_attribute (
      id_i IN NUMBER,
      deleted_by_i IN NUMBER,
      pDelete OUT number
    )
    IS
        l_juris_att_id NUMBER := id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_juris_id NUMBER; -- juris_tax_imposition_id
        l_attrib_id NUMBER;
        l_rid NUMBER;
        l_nkid NUMBER;
        l_rec_count number;
  BEGIN
    pDelete:=0;

    -- step check
    Select count(*) into l_rec_count
    from tax_attributes ja
    where ja.id=id_i;

    if l_rec_count = 1 then

    INSERT INTO tmp_delete(table_name, primary_key) VALUES ('TAX_ATTRIBUTES', l_juris_att_id);

    DELETE FROM tax_attributes ja
     WHERE ja.id = l_juris_att_id
       AND ja.status = 0
    RETURNING rid, nkid INTO l_rid, l_nkid;
    INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
    SELECT table_name, primary_key, l_deleted_by
      FROM tmp_delete
    );

    UPDATE tax_attributes jta
    SET next_Rid = NULL
    WHERE jta.next_rid = l_rid
      AND jta.nkid = l_nkid;
          pDelete := 1;
    else
          -- ToDo: Log here or in main procedure?
          -- UM_Log(l_juris_id, l_tax_desc_id, 0 {No can do}, sysdate);
          pDelete := 0;
    end if;
    EXCEPTION
         WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop (SQLCODE,SQLERRM||': '||id_i);
  END remove_tax_attribute;

  /** TAXES MAIN */
  PROCEDURE Tax_Definition(insx IN CLOB, success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER) IS
    definition_section XMLForm_TaxDefn_TT := XMLForm_TaxDefn_TT();
    thresholds_section XMLForm_TaxThres_TT := XMLForm_TaxThres_TT();
    reportcode_section XMLForm_TaxReportCode_TT := XMLForm_TaxReportCode_TT(); -- blank
    admin_section      XMLForm_TaxAdminRecs_TT := XMLForm_TaxAdminRecs_TT();   -- blank
    attributes_section XMLForm_TaxAddAttr_TT := XMLForm_TaxAddAttr_TT();       -- blank
    tag_list xmlform_tags_tt := xmlform_tags_tt();                             -- blank
    nRecordCount NUMBER := 0;
    sx CLOB;

    -- temp variable for taxdfn_row.id
    id_o           NUMBER;
    l_n_enteredby  NUMBER;
    l_xml_data     xmltype;
    outline_record NUMBER := 0;
    l_wrk_rid      NUMBER;

  BEGIN
    success := 0;

    FOR taxdfn_row IN
    ( SELECT * FROM TABLE( CAST( XMLForm_TaxesDefinition( XMLType(insx)
    ) AS XMLForm_TaxDefn_TT))
    ) LOOP <<mainloop>>
    definition_section.EXTEND;
    definition_section(definition_section.last) := XMLForm_TaxesDefine
                     ( taxdfn_row.id
                     , taxdfn_row.rid
                     , taxdfn_row.nkid
                     , taxdfn_row.jurisdiction_id
                     , taxdfn_row.taxdescriptionid
                     , taxdfn_row.revenuepurpose
                     , taxdfn_row.referencecode
                     , taxdfn_row.calculationstructureid
                     , taxdfn_row.description
                     , taxdfn_row.startdate
                     , taxdfn_row.enddate
                     , taxdfn_row.enteredby
                     , taxdfn_row.modified
                     , taxdfn_row.deleted
                     );

    id_o := taxdfn_row.id;
    -- This is really the one we use for update_multiple
    l_n_enteredby := taxdfn_row.enteredby;

    nkid_o := taxdfn_row.nkid;
    l_wrk_rid := taxdfn_row.rid;
    -- Thresholds
    l_xml_data :=  sys.XMLType(insx);

    FOR taxthr_row IN (SELECT
                       x.defntype
                     , to_date(x.startdate) startdate
                     , to_date(x.enddate) enddate
                     , x.taxoutlineid
                     , x.modified
                     , x.deleted
                     , ROWNUM throutlinerec
                     , x.threshold_detail
                 FROM xmltable('tax_upd_multiple/tax_definition_collection'
                                 passing l_xml_data
                                 columns
                                 defntype NUMBER path 'calculation_structure_id',
                                 startdate varchar2(16) path 'start_date',
                                 enddate varchar2(16) path 'end_date',
                                 taxoutlineid NUMBER path 'tax_outline_id',
                                 modified NUMBER path 'modified',
                                 deleted NUMBER path 'deleted',
                                 threshold_detail xmltype path
                                 'threshold_collection') x)
                                 LOOP

      FOR threshold_detail IN (SELECT y.id,
                                    y.rid,
                                    y.nkid,
                                    y.min_threshold,
                                    y.max_limit,
                                    y.value,
                                    y.value_type,
                                    y.ref_juris_tax_id,
                                    y.currency_id,
                                    y.thModified,
                                    y.thDeleted
                      FROM xmltable('/threshold_collection'
                                    passing taxthr_row.threshold_detail
                                    COLUMNS
                                    id NUMBER path 'id',
                                    rid NUMBER path 'rid',
                                    nkid NUMBER path 'nkid',
                                    min_threshold NUMBER path 'min_threshold',
                                    max_limit NUMBER path 'max_limit',
                                    value NUMBER path 'value',
                                    value_type varchar2(15) path 'value_type',
                                    ref_juris_tax_id varchar2(16) path 'ref_juris_tax_id',
                                    currency_id NUMBER path 'currency_id',
                                    thModified number path 'modified',
                                    thDeleted number path 'deleted'
                                    ) y) LOOP
        thresholds_section.EXTEND;
                    thresholds_section(thresholds_section.last) := XMLForm_TaxesThreshold
                    (  threshold_detail.id
                     , threshold_detail.rid
                     , threshold_detail.nkid
                     , taxthr_row.defntype
                     , null
                     , taxthr_row.startdate
                     , taxthr_row.enddate
                     , taxthr_row.taxoutlineid
                     , threshold_detail.min_threshold
                     , threshold_detail.max_limit
                     , threshold_detail.value_type
                     , threshold_detail.value
                     , threshold_detail.ref_juris_tax_id
                     , threshold_detail.currency_id
                     , taxthr_row.modified
                     , taxthr_row.deleted
                     , taxthr_row.throutlinerec
                     , threshold_detail.thModified
                     , threshold_detail.thDeleted
                     );
      END LOOP;

    END LOOP;

    -- Process form data
    taxlaw_taxes.process_form_detail(definition_section(definition_section.LAST) --::XMLForm_TaxesDefinition
                       ,thresholds_section         --::XMLForm_TaxThres_TT
                       ,reportcode_section         --::XMLForm_TaxReportCode_TT
                       ,admin_section              --::XMLForm_TaxAdminRecs_TT,
                       ,attributes_section         --::XMLForm_TaxAddAttr_TT
                       ,taxdfn_row.id
                       ,tag_list
                       ,rid_o
                       ,nkid_o);
  END LOOP mainloop;

    if (l_wrk_rid<>definition_section(definition_section.LAST).rid or l_wrk_rid is null) then
      rid_o := TAX.get_revision(rid_i => rid_o, entered_by_i => l_n_enteredby);
    else
      rid_o := l_wrk_rid; -- current rid passed in the XML
    end if;
    success := 1;

  END Tax_Definition;


  PROCEDURE process_xml(sx IN CLOB, success OUT NUMBER, process_id OUT NUMBER)
  IS
    errmsg clob:='Error multiple update';
    l_process_id number;
    nkid_o number;
    l_crud number;          -- local update/delete/insert flag
    Start_time number;      -- log start process time
    End_time number;        -- log end process time
    n_rec_tax_defn number;  -- record count for tax definitions
    pTax_Outline_id number:=null; -- init as new tax_definition
    vExists number:=0;
    n_defer_to_juris_tax_id number:=null;
    wstatus number:=1;
  BEGIN
    -- Get a process id (log)

    -- 6/8/2015
    -- In order to use the same change log redirect in the UI the 2 logs,
    -- copy tax and update multiple, needs to be joined.
    -- The difference will be the type of copy that was performed.
    -- 1 for update multiple
    -- 2 for copy tax
    -- (additional when other)
    -- process_id := update_multiple_process_sq.nextval;
    process_id := tax_log_id_seq.nextval;

    DBMS_OUTPUT.Put_Line( 'Process:'||process_id );

  -- JURISDICTION UPD/DEL/INS
  -- Try: get any data - Except: nothing to do if empty - Finally: Log and return
  -- (Suggestion: Move to individual procedures if performance is bad)
      SELECT
          h.crud,
          h.taxation_id,
          h.spec_app_id,
          h.trans_id,
          h.tax_descr,
          h.start_date,
          h.end_date,
          q.jurisdictions,
          q.entered_by
          BULK COLLECT INTO r_T_Juris
     from XMLTable('for $i in /juris_upd_multiple/tax_description return $i'
          passing
          xmltype(sx)
          columns
          crud number path 'crud',
          taxation_id number path 'taxation_type_id',
          spec_app_id number path 'spec_applicability_type_id',
          trans_id number path 'transaction_type_id',
          tax_descr number path 'tax_description_id',
          start_date varchar2(11) path 'start_date',
          end_date varchar2(11) path 'end_date'
          ) h,
          xmltable('/juris_upd_multiple'
          passing xmltype(sx)
          columns jurisdictions varchar2(4000) path 'jurisdiction_ids',
          entered_By number path 'entered_by') q;

    -- Jurisdiction Attributes
          SELECT
          h.crud,
          h.value,
          h.attribute_id,
          h.attribute_category_id,
          h.start_date,
          h.end_date,
          q.jurisdictions,
          q.entered_by
          BULK COLLECT INTO r_T_Juris_Attrib
          from XMLTable('for $i in /juris_upd_multiple/attribute return $i'
          passing
          xmltype(sx)
          columns
          crud number path 'crud',
          value varchar2(500) path 'value',
          attribute_id number path 'attribute_id',
          attribute_category_id number path 'attribute_category_id',
          start_date varchar2(11) path 'start_date',
          end_date varchar2(11) path 'end_date'
          ) h,
          xmltable('/juris_upd_multiple'
          passing xmltype(sx)
          columns jurisdictions varchar2(4000) path 'jurisdiction_ids',
          entered_By number path 'entered_by') q;

    -- Jurisdiction tags
          SELECT
          h.crud,
          h.tag_id,
          q.jurisdictions,
          q.entered_by
          BULK COLLECT INTO r_T_Juris_Tags
          from XMLTable('for $i in /juris_upd_multiple/tag return $i'
          passing
          xmltype(sx)
          columns
          crud number path 'crud',
          tag_id number path 'tag_id'
          ) h,
          xmltable('/juris_upd_multiple'
          passing xmltype(sx)
          columns jurisdictions varchar2(4000) path 'jurisdiction_ids',
          entered_By number path 'entered_by') q;

  -- TAX
  -- a/ check existing XML for definition sections
  -- b/ parse for either crud=1 or crud=2,3
  -- Tax Definitions (Todo: check procedure of type before executing)
  SELECT count(*)
  Into vExists
  FROM XMLTable('for $i in /tax_upd_multiple/tax_definition_collection return $i'
  passing
  xmltype(sx)
  columns
      crud number path 'crud' -- what are we doing with the XML here?
  ) h
  WHERE EXISTSNODE(xmltype(sx), '/tax_upd_multiple/tax_definition_collection/threshold_collection') = 1;

  if (vExists > 0) then
    SELECT
    h.crud,
    h.start_date,
    h.end_date,
    h.calculation_structure_id,
    h.tax_structure_type_id,
    q.tax_imposition_ids,
    q.entered_by,
    d.min_threshold,
    d.max_limit,
    d.value,
    d.value_type,
    d.currency_id,
    d.ref_juris_tax_id
    BULK COLLECT INTO r_T_Tax_Defn
    from XMLTable('for $i in /tax_upd_multiple/tax_definition_collection return $i'
    passing
    xmltype(sx)
    columns
      crud number path 'crud',
      start_date varchar2(11) path 'start_date',
      end_date varchar2(11) path 'end_date',
      calculation_structure_id number path 'calculation_structure_id',
      tax_structure_type_id number path 'tax_structure_type_id') h,
        xmltable('/tax_upd_multiple'
        passing xmltype(sx)
        columns tax_imposition_ids clob path 'imposition_ids',
        entered_By number path 'entered_by') q,
      xmltable('for $j in /tax_upd_multiple/tax_definition_collection/threshold_collection return $j'
      passing xmltype(sx)
      columns
      min_threshold number path 'min_threshold',
      max_limit number path 'max_limit',
      value number path 'value',
      value_type VARCHAR2(15) path 'value_type',
      currency_id number path 'currency_id',
      ref_juris_tax_id varchar2(12) path 'ref_juris_tax_id'
      ) d;
    else
      -- really wanted to use the bulk collect into instead of looping through
      -- with empty fields
      SELECT
      h.crud,
      h.start_date,
      h.end_date,
      h.calculation_structure_id,
      h.tax_structure_type_id,
      q.tax_imposition_ids,
      q.entered_by,
      null,
      null,
      null,
      null,
      null,
      null
      BULK COLLECT INTO r_T_Tax_Defn
      from XMLTable('for $i in /tax_upd_multiple/tax_definition_collection return $i'
      passing
      xmltype(sx)
      columns
        crud number path 'crud',
        start_date varchar2(11) path 'start_date',
        end_date varchar2(11) path 'end_date',
        calculation_structure_id number path 'calculation_structure_id',
        tax_structure_type_id number path 'tax_structure_type_id') h,
        xmltable('/tax_upd_multiple'
        passing xmltype(sx)
        columns tax_imposition_ids clob path 'imposition_ids',
        entered_By number path 'entered_by') q;
    end if;

    n_rec_tax_defn := r_T_Tax_Defn.Count;
    DBMS_OUTPUT.Put_Line('# Rec Tax Definitions:' || n_rec_tax_defn);

    -- Tax Reporting Code
          SELECT
          h.crud,
          h.value,
          h.attribute_id,
          h.start_date,
          h.end_date,
          q.jurisdictions,
          q.entered_by
          BULK COLLECT INTO r_T_Tax_Report
          from XMLTable('for $i in /tax_upd_multiple/reporting_code_collection return $i'
          passing
          xmltype(sx)
          columns
          crud number path 'crud',
          value varchar2(256) path 'value',
          attribute_id number path 'attribute_id',
          start_date varchar2(11) path 'start_date',
          end_date varchar2(11) path 'end_date'
          ) h,
          xmltable('/tax_upd_multiple'
          passing xmltype(sx)
          columns jurisdictions varchar2(4000) path 'imposition_ids',
          entered_By number path 'entered_by') q;

    -- Tax Administrator
          SELECT
          h.crud,
          h.admin_id,
          h.administrator_name,
          h.collects_tax,
          h.collector_id,
          h.start_date,
          h.end_date,
          q.jurisdictions,
          q.entered_by
          BULK COLLECT INTO r_T_Tax_Admin
          from XMLTable('for $i in /tax_upd_multiple/administrator_collection return $i'
          passing
          xmltype(sx)
          columns
          crud number path 'crud',
          admin_id number path 'admin_id',
          administrator_name varchar2(256) path 'administrator_name',
          collects_tax number path 'collects_tax',
          collector_id number path 'collector_id',
          start_date varchar2(11) path 'start_date',
          end_date varchar2(11) path 'end_date'
          ) h,
          xmltable('/tax_upd_multiple'
          passing xmltype(sx)
          columns jurisdictions varchar2(4000) path 'imposition_ids',
          entered_By number path 'entered_by') q;

    -- Tax Attributes
          SELECT
          h.crud,
          h.value,
          h.attribute_id,
          h.attribute_category_id,
          h.start_date,
          h.end_date,
          q.jurisdictions,
          q.entered_by
          BULK COLLECT INTO r_T_Tax_Attrib
          from XMLTable('for $i in /tax_upd_multiple/attribute_collection return $i'
          passing
          xmltype(sx)
          columns
          crud number path 'crud',
          value varchar2(500) path 'value',
          attribute_id number path 'attribute_id',
          attribute_category_id number path 'attribute_category_id',
          start_date varchar2(11) path 'start_date',
          end_date varchar2(11) path 'end_date'
          ) h,
          xmltable('/tax_upd_multiple'
          passing xmltype(sx)
          columns jurisdictions varchar2(4000) path 'imposition_ids',
          entered_By number path 'entered_by') q;

    -- Tax Tags
          SELECT
          h.crud,
          h.tag_id,
          q.jurisdictions,
          q.entered_by
          BULK COLLECT INTO r_T_Tax_Tags
          from XMLTable('for $i in /tax_upd_multiple/tag return $i'
          passing
          xmltype(sx)
          columns
          crud number path 'crud',
          tag_id number path 'tag_id'
          ) h,
          xmltable('/tax_upd_multiple'
          passing xmltype(sx)
          columns jurisdictions varchar2(4000) path 'imposition_ids',
          entered_By number path 'entered_by') q;

-- Taxability: lc_taxability script here
-- Todo: Add type to log
-- Todo: Add outline from Tax_Law package below (different out parameter)

  /** JURISDICTION tax_description ---------------------------------------------
   *
   */
  if r_T_Juris.Count > 0  then

    -- Tab for ID's to ins/del/upd
    Select regexp_substr(r_T_Juris(1).jl, '[^,]+', 1, level)
    BULK COLLECT INTO juris_id_tbl
    From dual
    Connect By regexp_substr(r_T_Juris(1).jl, '[^,]+', 1, level) is not null;

    Start_time := DBMS_UTILITY.get_time;
    FORALL lg in juris_id_tbl.first .. juris_id_tbl.last
    Insert Into update_multiple_log(process_id, genDate, status, entity, eid, action, mlt_section)
    Values(process_id, sysdate, 0, 2, juris_id_tbl(lg), 'E', 1);
    -- update_multiple_rec(processid=> process_id, status=> 0, entity=> 2, action=> 0, editid=> juris_id_tbl(lg), retnid=> ?, procsection=> 1);

    End_time := DBMS_UTILITY.get_time;
    DBMS_OUTPUT.PUT_LINE('Bulk Insert: '||to_char(End_time-start_time));

    -- Either LOOP or Insert all
    -- 1.
    -- - process table
    -- - id table
    -- join the two and use merge
    -- 2. loop call procedures in each package

    for i in r_T_Juris.First..r_T_Juris.Last
    loop
      -- add the records to process table? (pl/table for now)
      -- Get Tax Description - Existing or New
DBMS_OUTPUT.Put_Line( r_T_Juris(i).trans_id );
      l_td_id := jurisdiction.add_tax_description(r_T_Juris(i).trans_id, r_T_Juris(i).taxation_id, r_T_Juris(i).spec_app_id,
      r_T_Juris(i).entered_by );

      DBMS_OUTPUT.Put_Line('Tax Descr ID:'|| l_td_id );

      For j in juris_id_tbl.First..juris_id_tbl.Last
      Loop

            /* ---
             * From JURISDICTION PACKAGE
             */
             Select nvl(max(id),0) into l_td_pk
               from juris_tax_descriptions
              where jurisdiction_id = juris_id_tbl(j)
                and tax_description_id = l_td_id
                AND end_date is null;
                --and status = 0;

DBMS_OUTPUT.Put_Line( 'Tax descr id:'||l_td_pk );

-- log
update_multiple_rec(processid=>process_id, status=>1, entity=>2, action=>r_T_Juris(i).crud, editid=>juris_id_tbl(j), retnid=>l_td_pk, procsection=>1);

            -- procedure uses NULL for parameter td_pk
            IF l_td_pk = 0 THEN
              l_td_pk := NULL;  -- new juris tax description
            END IF;

            IF (NVL(r_T_Juris(i).crud,0) = 3 AND l_td_pk IS NOT NULL) THEN
                DBMS_OUTPUT.Put_Line( 'Try:Remove'||juris_id_tbl(j)||' '||l_td_pk);
                update_multiple.remove_tax_description(id_i => l_td_pk, deleted_by_i => 1, jurisdiction_id_i => juris_id_tbl(j), pDelete=>rTaxDescrDelete);
                DBMS_OUTPUT.Put_Line( 'Delete returned:'||rTaxDescrDelete );
            ELSIF (NVL(r_T_Juris(i).crud,0) < 3) THEN
                --> update or insert
                jurisdiction.update_tax_description(
                id_io => l_td_pk,
                jurisdiction_id_i => juris_id_tbl(j),
                tax_description_id_i => l_td_id,
                tran_type_id_i => r_T_Juris(i).trans_id,
                tax_type_id_i => r_T_Juris(i).taxation_id,
                spec_app_type_id_i => r_T_Juris(i).spec_app_id,
                start_date_i => r_T_Juris(i).start_date,
                end_date_i => r_T_Juris(i).end_date,
                entered_by_i => r_T_Juris(i).entered_By);
            END IF;

DBMS_OUTPUT.Put_Line( 'Action:'||r_T_Juris(i).crud );

            -- Log Delete Error
            IF rTaxDescrDelete=0 and r_T_Juris(i).crud = 3 then
               Update update_multiple_log
                  Set  status = -1
                      ,primary_key = l_td_pk
                Where process_id = process_id
                  and eid=juris_id_tbl(j)
                  and action='D';
               rTaxDescrDelete:=1;
            else
update_multiple_rec(processid=>process_id, status=>2, entity=>2, action=>r_T_Juris(i).crud, editid=>juris_id_tbl(j), retnid=>l_td_pk, procsection=>1);
            end if;

      end loop;

    end loop;
  else
    DBMS_OUTPUT.Put_Line( 'No Jurisdiction Tax Descriptions' );
    -- (depends on preference; Each section by itself or all in one)
    -- space for log or trace
  end if;  -- END JURISDICTION TAX DESCRIPTION


  /** Jurisdiction Attributes --------------------------------------------------
   *
   */
  if r_T_Juris_attrib.Count > 0  then
    DBMS_OUTPUT.Put_Line( 'Jurisdiction Attributes' );

    -- Tab for ID's to ins/del/upd
    -- Todo: add write a function for this one
    Select regexp_substr(r_T_Juris_attrib(1).jl, '[^,]+', 1, level)
    BULK COLLECT INTO juris_id_tbl
    From dual
    Connect By regexp_substr(r_T_Juris_attrib(1).jl, '[^,]+', 1, level) is not null;

    FORALL lg in juris_id_tbl.first .. juris_id_tbl.last
    Insert Into update_multiple_log(process_id, genDate, status, entity, eid, action, mlt_section)
    Values(process_id, sysdate, 0, 2, juris_id_tbl(lg), 'E', 2);

    for i in r_T_Juris_Attrib.First..r_T_Juris_Attrib.Last
    loop

      For j in juris_id_tbl.First..juris_id_tbl.Last
      Loop

-- 12/16 multiple? Might need to get a list here-->
        SELECT nvl(max(id),0)
        INTO l_att_pk
        from jurisdiction_attributes
        WHERE attribute_id=r_T_Juris_Attrib(i).attribute_id
        AND jurisdiction_id=juris_id_tbl(j)
        AND end_date is null;

update_multiple_rec(processid=>process_id, status=>1, entity=>2, action=>r_T_Juris_attrib(i).crud, editid=>juris_id_tbl(j), retnid=>l_att_pk, procsection=>2);

            IF l_att_pk = 0 THEN
              l_att_pk := NULL;  -- new juris tax description
            END IF;

            IF (NVL(r_T_Juris_attrib(i).crud,0) = 3 AND l_att_pk IS NOT NULL) THEN
            DBMS_OUTPUT.Put_Line( 'Remove..'||l_att_pk );
                update_multiple.remove_attribute(id_i=>l_att_pk, deleted_by_i=>r_T_Juris_attrib(i).entered_By, pDelete=>rJurisAttribDelete);
            ELSIF (NVL(r_T_Juris_attrib(i).crud,0) < 3) THEN

/* Exists in orig. Jurisdiction package. Error log is different*/
          IF (l_att_pk IS NOT NULL and NVL(r_T_Juris_attrib(i).crud,0) = 2) THEN
DBMS_OUTPUT.Put_Line( 'Update:'||l_att_pk );

            UPDATE jurisdiction_Attributes ja
            SET --ja.value = nvl(r_T_Juris_attrib(i).value,ja.value),
                ja.start_date = ja.start_date, --nvl(r_T_Juris_attrib(i).start_date,ja.start_date)
                ja.end_date = nvl(r_T_Juris_attrib(i).end_date,ja.end_date),
                ja.entered_by = r_T_Juris_attrib(i).entered_by
            WHERE ja.id = l_att_pk
            AND ja.end_date is null;
          ELSE
DBMS_OUTPUT.Put_Line( 'Insert:'||l_att_pk );
            INSERT INTO jurisdiction_attributes (
                jurisdiction_id,
                attribute_id,
                value, start_date,
                end_date,
                entered_by,
                rid
            ) VALUES (
                juris_id_tbl(j),
                r_T_Juris_attrib(i).attribute_id,
                r_T_Juris_attrib(i).value,
                r_T_Juris_attrib(i).start_date,
                r_T_Juris_attrib(i).end_date,
                r_T_Juris_attrib(i).entered_by,
                null
            ) RETURNING id INTO l_att_pk;
          END IF;
            DBMS_OUTPUT.Put_Line( 'New or Update:'||l_att_pk );

            -- Log Delete Error
            IF rJurisAttribDelete=0 and r_T_Juris_attrib(i).crud = 3 then
               Update update_multiple_log
                  Set  status = -1
                      ,primary_key = l_att_pk
                Where process_id = process_id
                  and eid=juris_id_tbl(j)
                  and action='D';
               rJurisAttribDelete:=1;
            else
               update_multiple_rec(processid=>process_id, status=>2, entity=>2, action=>r_T_Juris_attrib(i).crud, editid=>juris_id_tbl(j), retnid=>l_att_pk, procsection=>2);
            end if;

        end if;
DBMS_OUTPUT.Put_Line( 'Action:'||r_T_Juris_attrib(i).crud );
l_att_pk:=null;
        end loop;

    end loop;
  else
    DBMS_OUTPUT.Put_Line( 'No Jurisdiction Attributes' );
    -- (depends on preference; Each section by itself or all in one)
    -- space for log or trace
  end if;
  ------------------------------------------------------------------------------

  /* Jurisdiction TAGS */
  if r_T_Juris_Tags.Count>0 then
    Select regexp_substr(r_T_Juris_Tags(1).jl, '[^,]+', 1, level)
    BULK COLLECT INTO juris_id_tbl
    From dual
    Connect By regexp_substr(r_T_Juris_Tags(1).jl, '[^,]+', 1, level) is not null;

    Start_time := DBMS_UTILITY.get_time;
    FORALL lg in juris_id_tbl.first .. juris_id_tbl.last
    Insert Into update_multiple_log(process_id, genDate, status, entity, eid, action, mlt_section)
    Values(process_id, sysdate, 0, 2, juris_id_tbl(lg), 'E', 3);
    -- update_multiple_rec(processid=> process_id, status=> 0, entity=> 2, action=> 0, editid=> juris_id_tbl(lg), retnid=> ?, procsection=> 1);

    End_time := DBMS_UTILITY.get_time;
    DBMS_OUTPUT.PUT_LINE('Insert: '||to_char(End_time-start_time));

    for i in r_T_Juris_Tags.First..r_T_Juris_Tags.Last
    loop
      For j in juris_id_tbl.First..juris_id_tbl.Last
      Loop
        SELECT nkid INTO nkid_o
        FROM jurisdictions
        WHERE id = juris_id_tbl(j);
    DBMS_OUTPUT.Put_Line( nkid_o );

    update_multiple_rec(processid=>process_id, status=>1, entity=>2, action=>r_T_Juris_Tags(i).crud, editid=>juris_id_tbl(j), retnid=>nkid_o, procsection=>3);

    -- Build tag list
    -- tags_registry
    -- tag_list DS must be defined

      -- Convert crud to 0 or 1 for delete
      Select decode(r_T_Juris_Tags(i).crud,3,1,0) into l_crud from dual;
      tag_list.extend;
      tag_list( tag_list.last ):=xmlform_tags(
      2,
      nkid_o,
      r_T_Juris_Tags(i).entered_by,
      r_T_Juris_Tags(i).tag_id,
      l_crud,
      0);
      tags_registry.tags_entry(tag_list, nkid_o);
      DBMS_OUTPUT.Put_Line( tag_list.count );

      --tag_list.delete;
      end loop;

    end loop;

  else
    DBMS_OUTPUT.Put_Line( 'No Jurisdiction Tags' );
    -- (depends on preference; Each section by itself or all in one)
    -- space for log or trace
  end if;

  /* ************************************************************************ */

  /** TAX ------------------------------------------------------------------ */

    -- Tax Reporting Code
  if r_T_Tax_Report.Count > 0  then
    DBMS_OUTPUT.Put_Line( 'Tax Reporting Codes' );
    Select regexp_substr(r_T_Tax_Report(1).jl, '[^,]+', 1, level)
    BULK COLLECT INTO juris_id_tbl
    From dual
    Connect By regexp_substr(r_T_Tax_Report(1).jl, '[^,]+', 1, level) is not null;

    FORALL lg in juris_id_tbl.first .. juris_id_tbl.last
    Insert Into update_multiple_log(process_id, genDate, status, entity, eid, action, mlt_section)
    Values(process_id, sysdate, 0, 3, juris_id_tbl(lg), 'E', 2);

    For i in r_T_Tax_Report.First..r_T_Tax_Report.Last
    Loop

      For j in juris_id_tbl.First..juris_id_tbl.Last
      Loop
      DBMS_OUTPUT.Put_Line( 'Juris Imp Id:'||juris_id_tbl(j));

        if (NVL(r_T_Tax_Report(i).crud,0) <> 1) then
-- 4/28 I suspect this could fail since attributes can be flipped around specifying end date

         SELECT nvl(max(id),0)
         INTO l_att_pk
         From tax_attributes
         WHERE juris_tax_imposition_id=juris_id_tbl(j)
         and attribute_id=8 and end_date is null and next_rid is null;
         --and status<>2;
         update_multiple_rec(processid=>process_id, status=>1, entity=>3,
               action=>r_T_Tax_Report(i).crud,
               editid=>juris_id_tbl(j),
               retnid=>l_att_pk, procsection=>4);

        end if;

        IF l_att_pk = 0 THEN
           l_att_pk := NULL;  -- new juris tax description
        END IF;

          IF (NVL(r_T_Tax_Report(i).crud,0) = 3 AND l_att_pk IS NOT NULL) THEN
          DBMS_OUTPUT.Put_Line( 'Remove reporting code:'||l_att_pk );
              update_multiple.remove_tax_attribute(id_i=>l_att_pk, deleted_by_i=>r_T_Tax_Report(i).entered_By, pDelete=>rReportingCodeDelete);
          ELSIF (NVL(r_T_Tax_Report(i).crud,0) < 3) THEN

            IF (l_att_pk IS NOT NULL) THEN
/* !!
 * Start date should be required. What if the data does not have one? Should the
 * start date be the same as the Tax header start date?
   old:ja.start_date = nvl(r_T_Tax_Report(i).start_date,ja.start_date),
 */
              UPDATE tax_attributes ja
              SET
                ja.value = ja.value,
                ja.start_date = nvl(r_T_Tax_Report(i).start_date,ja.start_date),
                ja.end_date = nvl(r_T_Tax_Report(i).end_date,ja.end_date),
                ja.entered_by = r_T_Tax_Report(i).entered_by
              WHERE ja.id = l_att_pk
                AND ja.end_date is null;
            ELSE
DBMS_OUTPUT.Put_Line( 'ADD/UPDATE' );
              INSERT INTO tax_attributes (
                juris_tax_imposition_id,
                attribute_id,
                value, start_date,
                end_date,
                entered_by,
                rid
              ) VALUES (
                juris_id_tbl(j),
                8,
                r_T_Tax_Report(i).value,
                r_T_Tax_Report(i).start_date,
                r_T_Tax_Report(i).end_date,
                r_T_Tax_Report(i).entered_by,
                null
              ) RETURNING id INTO l_att_pk;
            END IF;
            DBMS_OUTPUT.Put_Line( 'New or Update:'||l_att_pk );

            -- Log Delete Error
            IF rReportingCodeDelete=0 and r_T_Tax_attrib(i).crud = 3 then
               Update update_multiple_log
                  Set  status = -1
                      ,primary_key = l_att_pk
                Where process_id = process_id
                  and eid=juris_id_tbl(j)
                  and action='D';
               rReportingCodeDelete:=1;
            else
              update_multiple_rec(processid=>process_id, status=>2, entity=>3, action=>r_T_Tax_Report(i).crud, editid=>juris_id_tbl(j), retnid=>l_att_pk, procsection=>2);
            end if;

        END IF;
        DBMS_OUTPUT.Put_Line( 'Action:'||r_T_Tax_Report(i).crud );
l_att_pk:=null;
        end loop;

    end loop;
  else
    DBMS_OUTPUT.Put_Line( 'No Tax Reporting Codes' );
    -- (depends on preference; Each section by itself or all in one)
    -- space for log or trace
  end if;


  -- Tax Administrator
  if r_T_Tax_Admin.Count > 0  then
    DBMS_OUTPUT.Put_Line( 'Tax Admin' );

    Select regexp_substr(r_T_Tax_Admin(1).jl, '[^,]+', 1, level)
    BULK COLLECT INTO juris_id_tbl
    From dual
    Connect By regexp_substr(r_T_Tax_Admin(1).jl, '[^,]+', 1, level) is not null;

    FORALL lg in juris_id_tbl.first .. juris_id_tbl.last
    Insert Into update_multiple_log(process_id, genDate, status, entity, eid, action, mlt_section)
    Values(process_id, sysdate, 0, 3, juris_id_tbl(lg), 'E', 3);

    for i in r_T_Tax_Admin.First..r_T_Tax_Admin.Last
    loop
DBMS_OUTPUT.Put_Line( r_T_Tax_Admin(i).admin_id );

      For j in juris_id_tbl.First..juris_id_tbl.Last
      Loop
        SELECT nvl(max(id),0)
        INTO l_att_pk
        from tax_administrators
        where administrator_id in (select id from administrators
        where nkid = (select nkid from administrators where id =r_T_Tax_Admin(i).admin_id))
        and juris_tax_imposition_id=juris_id_tbl(j);

        /* status?
        WHERE administrator_id=r_T_Tax_Admin(i).admin_id
        AND juris_tax_imposition_id=juris_id_tbl(j);
        */

        --log
        update_multiple_rec(processid=>process_id,
                            status=>1,
                            entity=>3,
                            action=>r_T_Tax_Admin(i).crud,
                            editid=>juris_id_tbl(j),
                            retnid=>l_att_pk,
                            procsection=>3);

            IF l_att_pk = 0 THEN
              l_att_pk := NULL;  -- new
            END IF;
        DBMS_OUTPUT.Put_Line( l_att_pk );

          IF (NVL(r_T_Tax_Admin(i).crud,0) = 3 AND l_att_pk IS NOT NULL) THEN
          DBMS_OUTPUT.Put_Line( 'Try Delete' );
              DELETE FROM tax_administrators
              WHERE id = l_att_pk;
          ELSIF (NVL(r_T_Tax_Admin(i).crud,0) < 3) THEN
            DBMS_OUTPUT.Put_Line( 'Try Update' );
            IF (l_att_pk IS NOT NULL) THEN
        -- XML does not contain tax_administrator id (never has) so here we pick it up in order to
        -- have the trigger handle the revision changes
               Update tax_administrators txa
               Set txa.start_date = nvl(r_T_Tax_Admin(i).start_date,txa.start_date)
                  ,txa.end_date = nvl(r_T_Tax_Admin(i).end_date,txa.end_date)
                  ,txa.collector_id = nvl(r_T_Tax_Admin(i).collector_id,txa.collector_id)
                  ,txa.entered_by = r_T_Tax_Admin(i).entered_by
                  ,txa.administrator_id = r_T_Tax_Admin(i).admin_id
               where txa.id =
(select txp.id from tax_administrators txp
where txp.administrator_id in (select id from administrators
where nkid = (select nkid from administrators where id =r_T_Tax_Admin(i).admin_id))
and juris_tax_imposition_id=juris_id_tbl(j)
and txp.next_rid is null);

/*               (select txp.id from tax_administrators txp
                where txp.administrator_id = r_T_Tax_Admin(i).admin_id
                and txp.juris_tax_imposition_id = juris_id_tbl(j)
                and txp.status<>1);*/

DBMS_OUTPUT.Put_Line( ' Update tax_administrators txa
               Set txa.start_date = '||r_T_Tax_Admin(i).start_date||'
                  ,txa.end_date = '||r_T_Tax_Admin(i).end_date||'
                  ,txa.collector_id = '||r_T_Tax_Admin(i).collector_id||'
                  ,txa.entered_by = '||r_T_Tax_Admin(i).entered_by||'
               where txa.id =
               (select txp.id from tax_administrators txp
                where txp.administrator_id = '||r_T_Tax_Admin(i).admin_id||'
                and txp.juris_tax_imposition_id = '||juris_id_tbl(j)||'
                and txp.status<>1);');

            else
            DBMS_OUTPUT.Put_Line( 'Try Insert' );
               Insert Into tax_administrators
               (juris_tax_imposition_id, administrator_id, start_date
               , end_date
               , entered_by
               , collector_id)
               Values
               (juris_id_tbl(j),
                r_T_Tax_Admin(i).admin_id,
                nvl(r_T_Tax_Admin(i).start_date, sysdate),
                nvl(r_T_Tax_Admin(i).end_date, null),
                r_T_Tax_Admin(i).entered_by,
                nvl(r_T_Tax_Admin(i).collector_id,null));
            end if;

            -- Log Delete Error
            IF rJurisAttribDelete=0 and r_T_Tax_Admin(i).crud = 3 then
               Update update_multiple_log
                  Set  status = -1
                      ,primary_key = l_att_pk
                Where process_id = process_id
                  and eid=juris_id_tbl(j)
                  and action='D';
               rJurisAttribDelete:=1;
            else
              update_multiple_rec(processid=>process_id, status=>2, entity=>3,
                                  action=>r_T_Tax_Admin(i).crud, editid=>juris_id_tbl(j),
                                  retnid=>l_att_pk, procsection=>3);
            end if;

        END IF;
        end loop;

    end loop;

  else
    DBMS_OUTPUT.Put_Line( 'No Tax Admin' );
    -- (depends on preference; Each section by itself or all in one)
    -- space for log or trace
  end if;


    -- Tax Additional Attributes
  if r_T_Tax_attrib.Count > 0  then
    DBMS_OUTPUT.Put_Line( 'Tax Attributes' );

    -- Tab for ID's to ins/del/upd
    -- Todo: add write a function for this one
    Select regexp_substr(r_T_Tax_attrib(1).jl, '[^,]+', 1, level)
    BULK COLLECT INTO juris_id_tbl
    From dual
    Connect By regexp_substr(r_T_Tax_attrib(1).jl, '[^,]+', 1, level) is not null;

    FORALL lg in juris_id_tbl.first .. juris_id_tbl.last
    Insert Into update_multiple_log(process_id, genDate, status, entity, eid, action, mlt_section)
    Values(process_id, sysdate, 0, 3, juris_id_tbl(lg), 'E', 4);

    for i in r_T_Tax_Attrib.First..r_T_Tax_Attrib.Last
    loop

      For j in juris_id_tbl.First..juris_id_tbl.Last
      Loop
DBMS_OUTPUT.Put_Line( r_T_Tax_Attrib(i).attribute_id );

        SELECT nvl(max(id),0)
        INTO l_att_pk
        from tax_attributes
        WHERE attribute_id=r_T_Tax_Attrib(i).attribute_id
        AND juris_tax_imposition_id=juris_id_tbl(j)
        and attribute_id<>8 and status<>2;

        --12/16 could there be multiple
        update_multiple_rec(processid=>process_id, status=>1, entity=>3, action=>r_T_Tax_attrib(i).crud, editid=>juris_id_tbl(j), retnid=>l_att_pk, procsection=>4);

            IF l_att_pk = 0 THEN
              l_att_pk := NULL;  -- new juris tax description
            END IF;

            IF (NVL(r_T_Tax_attrib(i).crud,0) = 3 AND l_att_pk IS NOT NULL) THEN
            DBMS_OUTPUT.Put_Line( 'Remove..'||l_att_pk );
                update_multiple.remove_tax_attribute(id_i=>l_att_pk, deleted_by_i=>r_T_Tax_attrib(i).entered_By, pDelete=>rJurisAttribDelete);
            ELSIF (NVL(r_T_Tax_attrib(i).crud,0) < 3) THEN

--CRAPP-2047
          IF (l_att_pk IS NOT NULL) THEN
            UPDATE tax_attributes ja
            SET --ja.value = r_T_Tax_attrib(i).value,
                ja.value = ja.value,
                ja.start_date = nvl(r_T_Tax_attrib(i).start_date,ja.start_date),
                ja.end_date = nvl(r_T_Tax_attrib(i).end_date,ja.end_date),
                ja.entered_by = r_T_Tax_attrib(i).entered_by
            WHERE ja.id = l_att_pk
              AND ja.end_date is null;
          ELSE
            INSERT INTO tax_attributes (
                juris_tax_imposition_id,
                attribute_id,
                value,
                start_date,
                end_date,
                entered_by
            ) VALUES (
                juris_id_tbl(j),
                r_T_Tax_attrib(i).attribute_id,
                r_T_Tax_attrib(i).value,
                r_T_Tax_attrib(i).start_date,
                r_T_Tax_attrib(i).end_date,
                r_T_Tax_attrib(i).entered_by
            ) RETURNING id INTO l_att_pk;
          END IF;
            DBMS_OUTPUT.Put_Line( 'New or Update:'||l_att_pk );
--END CRAPP-2047

            -- Log Delete Error
            IF rJurisAttribDelete=0 and r_T_Tax_attrib(i).crud = 3 then
               Update update_multiple_log
                  Set  status = -1
                      ,primary_key = l_att_pk
                Where process_id = process_id
                  and eid=juris_id_tbl(j)
                  and action='D';
               rJurisAttribDelete:=1;
            else
              update_multiple_rec(processid=>process_id,
                                             status=>2,
                                             entity=>3,
                                             action=>r_T_Tax_attrib(i).crud,
                                             editid=>juris_id_tbl(j),
                                             retnid=>l_att_pk,
                                             procsection=>4);
            end if;

        END IF;
          DBMS_OUTPUT.Put_Line( 'Action:'||r_T_Tax_attrib(i).crud );
        end loop;

    end loop;
  else
    DBMS_OUTPUT.Put_Line( 'No Tax Attributes' );
    -- (depends on preference; Each section by itself or all in one)
    -- space for log or trace
  end if;


    -- Tax Tags
    if r_T_Tax_Tags.Count>0 then
      -- Todo: Move to its own PROC
      Select regexp_substr(r_T_Tax_Tags(1).jl, '[^,]+', 1, level)
      BULK COLLECT INTO juris_id_tbl
      From dual
      Connect By regexp_substr(r_T_Tax_Tags(1).jl, '[^,]+', 1, level) is not null;

    Start_time := DBMS_UTILITY.get_time;
    FORALL lg in juris_id_tbl.first .. juris_id_tbl.last
    Insert Into update_multiple_log(process_id, genDate, status, entity, eid, action, mlt_section)
    Values(process_id, sysdate, 0, 3, juris_id_tbl(lg), 'E', 5);
    -- update_multiple_rec(processid=> process_id, status=> 0, entity=> 2, action=> 0, editid=> juris_id_tbl(lg), retnid=> ?, procsection=> 1);

    End_time := DBMS_UTILITY.get_time;
    DBMS_OUTPUT.PUT_LINE('Insert: '||to_char(End_time-start_time));

    for i in r_T_Tax_Tags.First..r_T_Tax_Tags.Last
    loop
      For j in juris_id_tbl.First..juris_id_tbl.Last
      Loop
        SELECT nkid INTO nkid_o
        FROM juris_tax_impositions
        WHERE id = juris_id_tbl(j);
    DBMS_OUTPUT.Put_Line( nkid_o );

    -- Tax Imposition NKID (current or new)
    update_multiple_rec(processid=>process_id, status=>1, entity=>3, action=>r_T_Tax_Tags(i).crud, editid=>juris_id_tbl(j), retnid=>nkid_o, procsection=>3);

    -- Build tag list
    -- tags_registry
      -- Convert crud to 0 or 1 for delete
      Select decode(r_T_Tax_Tags(i).crud,3,1,0) into l_crud from dual;
      tag_list.extend;
      tag_list( tag_list.last ):=xmlform_tags(
      3,
      nkid_o,
      r_T_Tax_Tags(i).entered_by,
      r_T_Tax_Tags(i).tag_id,
      l_crud,
      0);
      tags_registry.tags_entry(tag_list, nkid_o);
      DBMS_OUTPUT.Put_Line( tag_list.count );

      --tag_list.delete;
      end loop;

    end loop;

  else
    DBMS_OUTPUT.Put_Line( 'No Tax Tags' );
    -- (depends on preference; Each section by itself or all in one)
    -- space for log or trace
  end if;


  -- TAX DEFINITIONS
DBMS_OUTPUT.Put_Line( r_T_Tax_Defn.Count );

    if r_T_Tax_Defn.Count > 0  then
      Start_time := DBMS_UTILITY.get_time;

-- EQQ
/*    Type id_tt is table of varchar2(16);
    id_rs it_tt:=id_tt();
    id_reccount number:=0;*/

with test as (select ''''||replace(r_T_Tax_Defn(1).tax_imposition_ids,',',''''||','||' ''')||'''' colx from dual)
select xt.column_value.getClobVal()
bulk collect into id_rs
from xmltable((select colx from test)) xt;
for id_list in id_rs.first..id_rs.last
loop
 juris_id_tbl.extend;
 id_reccount:=id_reccount+1;
 juris_id_tbl(juris_id_tbl.last):=id_rs(id_list);
end loop;
DBMS_OUTPUT.Put_Line( 'Records:'||id_reccount );

/*
      Select regexp_substr(r_T_Tax_Defn(1).tax_imposition_ids, '[^,]+', 1, level)
      BULK COLLECT INTO juris_id_tbl
      From dual
      Connect By regexp_substr(r_T_Tax_Defn(1).tax_imposition_ids, '[^,]+', 1, level) is not null;
*/
      FORALL lg in juris_id_tbl.first .. juris_id_tbl.last
      Insert Into update_multiple_log(process_id, genDate, status, entity, eid, action, mlt_section)
      Values(process_id, sysdate, 0, 3, juris_id_tbl(lg), 'E', 1);


       For j in juris_id_tbl.First..juris_id_tbl.Last
       Loop

      for i in r_T_Tax_Defn.First..r_T_Tax_Defn.Last
      loop
          IF (NVL(r_T_Tax_Defn(i).crud,0) > 1) then
            SELECT nvl(max(id),0) -- if none
            INTO l_att_pk
            from tax_outlines
            WHERE juris_tax_imposition_id=juris_id_tbl(j)
-- 9/8
            AND status<>2;
            --and end_date is null;
          else
            l_att_pk :=0;
          end if;

          update_multiple_rec(processid=>process_id, status=>1, entity=>3, action=>r_T_Tax_Defn(i).crud, editid=>juris_id_tbl(j), retnid=>l_att_pk, procsection=>1);
          IF l_att_pk = 0 THEN
             l_att_pk := NULL;  -- new id (yes...name should be changed)
          END IF;

-- 9/8
DBMS_OUTPUT.Put_Line( 'Process:'||process_id );


          -- Delete
            IF (NVL(r_T_Tax_Defn(i).crud,0) = 3 AND l_att_pk IS NOT NULL) THEN
                DELETE FROM tax_definitions
                where tax_outline_id = l_att_pk
                return 0 into rTaxDefnDelete;
                -- DEL outline if no tax_definitions are available.
                DELETE FROM tax_outlines
                WHERE id = l_att_pk;
            ELSIF (NVL(r_T_Tax_Defn(i).crud,0) < 3) THEN
            -- Update
              IF (l_att_pk IS NOT NULL) THEN

-- 9/8 only allowing to change end_date
DBMS_OUTPUT.Put_Line( 'l_att_pk:'||l_att_pk );
                 UPDATE tax_outlines txo
                 SET end_date = nvl(r_T_Tax_Defn(i).end_date, txo.end_date)
                 , entered_by = r_T_Tax_Defn(i).entered_by
                 WHERE id = l_att_pk;
                 -- AND next_rid is null; -- test 9/7/16 New revision if status is 2 and should be handled by trigger
              ELSE

DBMS_OUTPUT.Put_Line( 'Outline is null' );
-- 9/8 new only for CRUD = 1, the other updates are handled by trigger if a new revision is needed
              if (pTax_Outline_id is null) and r_T_Tax_Defn(i).calculation_structure_id is not null then
--and NVL(r_T_Tax_Defn(i).crud,0) = 1
                   INSERT INTO tax_outlines (
                         juris_tax_imposition_id,
                         calculation_structure_id,
                         start_date,
                         end_date,
                         entered_by
                        )
                   VALUES (juris_id_tbl(j),
                     r_T_Tax_Defn(i).calculation_structure_id,
                     r_T_Tax_Defn(i).start_date,
                     r_T_Tax_Defn(i).end_date,
                     r_T_Tax_Defn(i).entered_by)
                   RETURNING id
                   INTO pTax_Outline_id;
              else
                   -- Exception needed here if message should be sent back
                   null;
              end if;

               -- Insert Threshold items
               IF (pTax_Outline_id IS NOT NULL) AND (r_T_Tax_Defn(i).crud =1) THEN
                 n_defer_to_juris_tax_id := getJurisImpRefId(juris_id_tbl(j), r_T_Tax_Defn(i).ref_juris_tax_id);

                 DBMS_OUTPUT.Put_Line( 'n_defer_to_juris_tax_id:'||n_defer_to_juris_tax_id );
                 -- DEFER_TO_JURIS_TAX_NKID is populated through the UPDATE trigger on TAX_DEFINITIONS table
                 -- based on the ID of the juris_tax_imposition
                 if n_defer_to_juris_tax_id = -1 then
                    DBMS_OUTPUT.Put_Line( 'No data found for this record...log.' );
                 else
                 INSERT INTO tax_definitions
                 (tax_outline_id, min_threshold, max_limit, value_type, value,
                  defer_to_juris_tax_id, currency_id, entered_by)
                 VALUES
                 (pTax_Outline_id, r_T_Tax_Defn(i).min_threshold,
                  r_T_Tax_Defn(i).max_limit, r_T_Tax_Defn(i).value_type, r_T_Tax_Defn(i).value,
                  n_defer_to_juris_tax_id, r_T_Tax_Defn(i).currency_id, r_T_Tax_Defn(i).entered_by);
                 end if;

               END IF;

              END IF;
            DBMS_OUTPUT.Put_Line( 'New or Update:'||l_att_pk );

            -- Log Delete Error
            IF rTaxDefnDelete=0 and r_T_Tax_Defn(i).crud = 3 then
              Update update_multiple_log
                 Set  status = -1
                     ,primary_key = l_att_pk
               Where process_id = process_id
                 and eid=juris_id_tbl(j)
                 and action='D';
              rJurisAttribDelete:=1;
            else
              update_multiple_rec(processid=>process_id, status=>2, entity=>3, action=>r_T_Tax_Defn(i).crud, editid=>juris_id_tbl(j), retnid=>pTax_Outline_id, procsection=>1);
            end if;
          End if;
          DBMS_OUTPUT.Put_Line( 'Action:'||r_T_Tax_Defn(i).crud );
       End loop;
       pTax_Outline_id := null;
    End loop;

      End_time := DBMS_UTILITY.get_time;
      DBMS_OUTPUT.PUT_LINE('Insert: '||to_char(End_time-start_time));
    Else
    DBMS_OUTPUT.Put_Line( 'No Tax Definitions' );
    -- (depends on preference; Each section by itself or all in one)
    -- ToDo: log or trace
    end if;

    ----------------------------------------------------------------------------
    /* Record Status Information (if needed) */
    /*  DBMS_OUTPUT.Put_Line( 'Record status:'||process_id );
    Select count(*) RC
    into wstatus
    From update_multiple_log
    Where process_id=process_id AND status=-1;
    DBMS_OUTPUT.Put_Line( wstatus );
    if (wstatus > 0) Then
      success := 0;
    else
    */
    success := 1;

  DBMS_OUTPUT.Put_Line( 'End' );

  EXCEPTION
       WHEN OTHERS THEN
       dbms_output.put_line(SubStr('Error '||TO_CHAR(SQLCODE)||': '||SQLERRM, 1, 255));
       dbms_output.put_line(dbms_utility.format_error_backtrace);
       ROLLBACK;
       RAISE;
  END process_xml;

END update_multiple;
/