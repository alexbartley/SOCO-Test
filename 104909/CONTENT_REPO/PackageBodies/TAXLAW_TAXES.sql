CREATE OR REPLACE PACKAGE BODY content_repo."TAXLAW_TAXES" 
IS

  STATUS_PUBLISHED constant number := 2;  -- no lookup for now

  function frmChangeSection(change_class in number) return varchar2
  is
    qstr varchar2(256);
    TYPE sectionRecord IS RECORD
         (jt_table varchar2(32),
          selcolumn varchar2(32));

    -- TT
    TYPE sectionTable IS TABLE OF sectionRecord;
    sections sectionTable;

  begin
      sections := sectionTable();
      sections.extend();
      sections(1).jt_table :='tax_outlines txo on (txo.juris_tax_imposition_id = txv.id)
                              join tax_definitions txd on (txd.tax_outline_id = txo.id)';
      sections(1).selcolumn  :='txv.id';
      --sections(1).critcolum := '';
      sections.extend();
      sections(2).jt_table :='tax_attributes txat on (txat.juris_tax_imposition_id = txv.id)';
      sections(2).selcolumn  :='txv.id';
      --sections(2).critcolum := 'txat.attribute_id = 8';
      sections.extend();
      sections(3).jt_table :='tax_administrators txa on (txa.juris_tax_imposition_id = txv.id)';
      sections(3).selcolumn  :='txv.id';
      --sections(3).critcolum := 'txat.start_date = ';
      sections.extend();
      sections(4).jt_table :='tax_attributes txat on (txat.juris_tax_imposition_id = txv.id)';
      sections(4).selcolumn  :='txv.id';
      --sections(4).critcolum := 'txat.attribute_id <> 8';
      sections.extend();
      sections(5).jt_table :='juris_tax_imposition_tags txtg on (txtg.juris_tax_imposition_id = txv.id)';
      sections(5).selcolumn  :='txv.id';
      --sections(5).critcolum := '';

      qstr:='JOIN '||sections(change_class).jt_table;
      --    where ... sections(iEntityType).setcolumn
      --    where ... sections(iEntityType).critcolumn

      RETURN qstr;
  end;


  ------------------------------------------------------------------------
  -- Tax Definitions XML
  --
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
      '/jurisdictiontaxes'
      PASSING poxml
                        COLUMNS id   NUMBER PATH 'id',
                                rid   NUMBER PATH 'rid',
                                nkid   NUMBER PATH 'nkid',
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

  ------------------------------------------------------------------------
  -- Thresholds XML
  --
  FUNCTION XMLForm_TaxesThresholds(form_xml_i IN XMLType)
           RETURN XMLForm_TaxThres_TT PIPELINED IS
    i             BINARY_INTEGER := 1;
    l_end_date    sys.XMLType;
    l_start_date  sys.XMLType;
    l_description sys.XMLType;
    out_rec       XMLForm_TaxesThreshold;  -- obj Threshold
    pxml          sys.XMLType := form_xml_i;
    poxml         sys.XMLType;
    xmlHDR        sys.XMLType;
    -- XML record #
    rec_count BINARY_INTEGER := 1;
    v_thrs BINARY_INTEGER:=1;

    chkTag        sys.XMLType;
  BEGIN
    out_rec := XMLForm_TaxesThreshold(NULL, NULL, NULL, NULL, NULL, NULL, NULL
               , NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

    WHILE pxml.existsNode('//'||xmlRoot||'/tax_definition_collection[' || rec_count || ']') = 1 LOOP

      chkTag:=pxml.extract('//'||xmlRoot||'/tax_definition_collection[' || rec_count || ']/calculation_structure_id/text()');
      IF (chkTag IS NOT NULL) THEN
        out_rec.defntype := chkTag.getNumberVal();
      END IF;

      chkTag:=pxml.extract('//'||xmlRoot||'/tax_definition_collection[' || rec_count || ']/tax_outline_id/text()');
      IF (chkTag IS NOT NULL) THEN
        out_rec.taxoutlineid := chkTag.getNumberVal();
      END IF;

      l_start_date := pxml.extract('//'||xmlRoot||'/tax_definition_collection[' || rec_count || ']/start_date/text()');
      IF (l_start_date IS NOT NULL) THEN
          out_rec.startdate := l_start_date.getStringVal();
      END IF;

      l_end_date := pxml.extract('//'||xmlRoot||'/tax_definition_collection[' || rec_count || ']/end_date/text()');
      IF (l_end_date IS NOT NULL) THEN
         out_rec.enddate := l_end_date.getStringVal();
      END IF;

      poxml := pxml.extract('//'||xmlRoot||'/tax_definition_collection[' || rec_count || ']');
      WHILE poxml.existsNode('/tax_definition_collection[' || rec_count || ']/threshold_collection[' || v_thrs || ']') = 1 LOOP

        chkTag := poxml.extract('/id/text()');
        IF (chkTag IS NOT NULL) THEN
          out_rec.id := chkTag.getNumberVal();
        END IF;

        -- Threshold outline record number
        out_rec.throutlinerec := rec_count;
        v_thrs := v_thrs + 1;

        PIPE ROW(out_rec);
        out_rec := XMLForm_TaxesThreshold(NULL, NULL, NULL, NULL, NULL, NULL, NULL
                 , NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
      END LOOP;
      rec_count := rec_count + 1;
    END LOOP;
    RETURN;
  END XMLForm_TaxesThresholds;

  ------------------------------------------------------------------------
  -- Reporting Codes XML
  --
    FUNCTION XMLForm_TaxesReportCode(form_xml_i IN XMLType)
           RETURN XMLForm_TaxReportCode_TT PIPELINED IS
    out_rec      XMLForm_TaxesReporting;  -- Reporting code
    poxml        sys.XMLType;
    i            binary_integer := 1;
    l_form_xml   sys.XMLType := form_xml_i;
    l_end_date   sys.XMLType;
    l_start_date sys.XMLType;
    l_repcode    sys.XMLType;
    xmlHDR       sys.XMLType;
    chkMeStr sys.XMLType;
  BEGIN
    out_rec := XMLForm_TaxesReporting(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

    -- HDR (disregard.  could be generic - for future use)
    xmlHDR := l_form_xml.extract('//'||xmlRoot||'['||i||']');

    LOOP
    poxml := l_form_xml.extract('//'||xmlRoot||'/reporting_code_collection['||i||']'); --
    EXIT WHEN poxml IS NULL;

      chkMeStr:=poxml.extract('reporting_code_collection/id/text()');
      IF (chkMeStr IS NOT NULL) THEN
        out_rec.id := chkMeStr.getNumberVal();
      END IF;

      chkMeStr:=poxml.extract('reporting_code_collection/rid/text()');
      IF (chkMeStr IS NOT NULL) THEN
        out_rec.rid := chkMeStr.getNumberVal();
      END IF;

      chkMeStr:=poxml.extract('reporting_code_collection/nkid/text()');
      IF (chkMeStr IS NOT NULL) THEN
        out_rec.nkid := chkMeStr.getNumberVal();
      END IF;

      chkMeStr:=poxml.extract('reporting_code_collection/modified/text()');
      IF (chkMeStr IS NOT NULL) THEN
        out_rec.modified := chkMeStr.getNumberVal();
      ELSE
        out_rec.modified := 0;
      END IF;

      chkMeStr:=poxml.extract('reporting_code_collection/deleted/text()');
      IF (chkMeStr IS NOT NULL) THEN
        out_rec.deleted := chkMeStr.getNumberVal();
      ELSE
        out_rec.deleted := 0;
      END IF;

      l_start_date := poxml.extract('reporting_code_collection/start_date/text()');
      IF (l_start_date IS NOT NULL) THEN
        out_rec.startdate := l_start_date.getStringVal();
      END IF;

      l_end_date := poxml.extract('reporting_code_collection/end_date/text()');
      IF (l_end_date IS NOT NULL) THEN
        out_rec.enddate := l_end_date.getStringVal();
      END IF;

      l_repcode := poxml.extract('reporting_code_collection/value/text()');
      IF (l_repcode IS NOT NULL) THEN
        out_rec.repcode := l_repcode.getStringVal();
      END IF;

      PIPE ROW(out_rec);
      i := i + 1;
    END LOOP;
    RETURN;
  END XMLForm_TaxesReportCode;

  /** Administrators XML
   *
   */
  FUNCTION XMLForm_TaxesAdminRecs(form_xml_i IN XMLType)
           RETURN XMLForm_TaxAdminRecs_TT PIPELINED IS
    out_rec XMLForm_TaxesAdmin;  -- obj Admin
    poxml   sys.XMLType;
    i       binary_integer := 1;
    l_form_xml  sys.XMLType := form_xml_i;
    l_end_date sys.XMLType;
    l_start_date sys.XMLType;
    l_repcode sys.XMLType;
    -- Check null values (old style)
    chkMeStr sys.XMLType;
  BEGIN
  LOOP
    out_rec := XMLForm_TaxesAdmin(NULL, NULL, NULL, NULL, NULL, NULL, NULL
               , NULL, NULL, NULL);
    poxml := l_form_xml.extract('//'||xmlRoot||'/administrator_collection['||i||']'); --
    EXIT WHEN poxml IS NULL;

    -- Check null values (old style)
    chkMeStr:=poxml.extract('administrator_collection/id/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.id := chkMeStr.getNumberVal();
    END IF;

    chkMeStr:=poxml.extract('administrator_collection/rid/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.rid := chkMeStr.getNumberVal();
    END IF;

    chkMeStr:=poxml.extract('administrator_collection/nkid/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.nkid := chkMeStr.getNumberVal();
    END IF;

    chkMeStr:=poxml.extract('administrator_collection/admin_id/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.administrator_id := chkMeStr.getNumberVal();
    END IF;

    chkMeStr:=poxml.extract('administrator_collection/collects_tax/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.admincollects := chkMeStr.getNumberVal();
    END IF;

    chkMeStr:=poxml.extract('administrator_collection/modified/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.modified := chkMeStr.getNumberVal();
    ELSE
      out_rec.modified := 0;
    END IF;

    chkMeStr:=poxml.extract('administrator_collection/deleted/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.deleted := chkMeStr.getNumberVal();
    ELSE
      out_rec.deleted := 0;
    END IF;

    l_start_date := poxml.extract('administrator_collection/start_date/text()');
    IF (l_start_date IS NOT NULL) THEN
        out_rec.admin_start := l_start_date.getStringVal();
    END IF;

    l_end_date := poxml.extract('administrator_collection/end_date/text()');
    IF (l_end_date IS NOT NULL) THEN
        out_rec.admin_end := l_end_date.getStringVal();
    END IF;

    l_repcode := poxml.extract('administrator_collection/collector_id/text()');
    IF (l_repcode IS NOT NULL) THEN
        out_rec.admincollector := l_repcode.getStringVal();
    else
        out_rec.admincollector := null;
    END IF;

    PIPE ROW(out_rec);
    i := i + 1;
    END LOOP;
    RETURN;

  END XMLForm_TaxesAdminRecs;

  /** Additional Attributes XML
   *
   */
  FUNCTION XMLForm_TaxesAddAttrib(form_xml_i IN XMLType)
           RETURN XMLForm_TaxAddAttr_TT PIPELINED IS
    out_rec XMLForm_TaxesAttrib;
    poxml   sys.XMLType;
    i       binary_integer := 1;
    l_form_xml  sys.XMLType := form_xml_i;
    l_end_date sys.XMLType;
    l_start_date sys.XMLType;
    l_aname sys.XMLType;
    l_avalue sys.XMLType;
    l_repcode sys.XMLType;
    chkMeStr sys.XMLType;
  BEGIN
  LOOP
    out_rec := XMLForm_TaxesAttrib(NULL, NULL, NULL, NULL, NULL, NULL, NULL
               , NULL, NULL, NULL);

    poxml := l_form_xml.extract('//'||xmlRoot||'/attribute_collection['||i||']'); --
    EXIT WHEN poxml IS NULL;

    -- Check null values (old style)
    chkMeStr:=poxml.extract('attribute_collection/id/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.id := chkMeStr.getNumberVal();
    END IF;

    chkMeStr:=poxml.extract('attribute_collection/rid/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.rid := chkMeStr.getNumberVal();
    END IF;

    chkMeStr:=poxml.extract('attribute_collection/nkid/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.nkid := chkMeStr.getNumberVal();
    END IF;

    chkMeStr:=poxml.extract('attribute_collection/attribute_id/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.attribute_id := chkMeStr.getNumberVal();
    END IF;

    chkMeStr:=poxml.extract('attribute_collection/modified/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.modified := chkMeStr.getNumberVal();
    ELSE
      out_rec.modified := 0;
    END IF;

    chkMeStr:=poxml.extract('attribute_collection/deleted/text()');
    IF (chkMeStr IS NOT NULL) THEN
      out_rec.deleted := chkMeStr.getNumberVal();
    ELSE
      out_rec.deleted := 0;
    END IF;

    l_aname := poxml.extract('attribute_collection/attribute_name/text()');
    IF (l_aname IS NOT NULL) THEN
        out_rec.aname := l_aname.getStringVal();
    END IF;

    l_avalue := poxml.extract('attribute_collection/value/text()');
    IF (l_avalue IS NOT NULL) THEN
        --out_rec.avalue := l_avalue.getStringVal();
        -- Old xml style does not handle CDATA well.
        out_rec.avalue :=REPLACE(REPLACE(l_avalue.getStringVal(),'<![CDATA[',''),']]>','');
    END IF;

    l_start_date := poxml.extract('attribute_collection/start_date/text()');
    IF (l_start_date IS NOT NULL) THEN
        out_rec.attrStartDate := l_start_date.getStringVal();
    END IF;

    l_end_date := poxml.extract('attribute_collection/end_date/text()');
    IF (l_end_date IS NOT NULL) THEN
        out_rec.attrenddate := l_end_date.getStringVal();
    END IF;

    PIPE ROW(out_rec);
    i := i + 1;
    END LOOP;
    RETURN;
  END XMLForm_TaxesAddAttrib;


  /** Parse a list of values -> selected_string type
   *  Return TABLE with values to be used for copying tax
   */
  FUNCTION fParseList(pList VARCHAR2) RETURN selected_string IS
    v_len   CONSTANT INTEGER := nvl(length(pList), 0);
    v_out   selected_string;
    v_i     INTEGER := 1;
    v_j     INTEGER;
  BEGIN
    LOOP
    EXIT WHEN v_i > v_len;
      v_j := instr(pList, ',', v_i);
      IF v_j = 0 THEN v_j := v_len + 1; END IF;
      v_out(v_out.COUNT + 1) := substr(pList, v_i, v_j-v_i);
      v_i := v_j + 1;
    END LOOP;
    RETURN v_out;
  END;


  /** Process Taxes main form
   *
   */
  PROCEDURE XMLProcess_Form_Taxes(insx IN CLOB, success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER) IS
    definition_section XMLForm_TaxDefn_TT := XMLForm_TaxDefn_TT();
    thresholds_section XMLForm_TaxThres_TT := XMLForm_TaxThres_TT();
    reportcode_section XMLForm_TaxReportCode_TT := XMLForm_TaxReportCode_TT();
    admin_section      XMLForm_TaxAdminRecs_TT := XMLForm_TaxAdminRecs_TT();
    attributes_section XMLForm_TaxAddAttr_TT := XMLForm_TaxAddAttr_TT();

    tag_list xmlform_tags_tt := xmlform_tags_tt();

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
                 FROM xmltable('jurisdictiontaxes/tax_definition_collection'
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
                                    ref_juris_tax_id NUMBER path 'ref_juris_tax_id',
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


    --Administrator
    FOR taxes_admin_row IN
      ( SELECT * FROM TABLE( CAST( XMLForm_TaxesAdminRecs( XMLType(insx)
      ) AS XMLForm_TaxAdminRecs_TT))
    ) LOOP <<a>>
        admin_section.EXTEND;
        admin_section(admin_section.LAST) := XMLForm_TaxesAdmin
                     ( taxes_admin_row.id
                     , taxes_admin_row.rid
                     , taxes_admin_row.nkid
                     , taxes_admin_row.administrator_id
                     , taxes_admin_row.admincollects
                     , taxes_admin_row.admincollector
                     , taxes_admin_row.admin_start
                     , taxes_admin_row.admin_end
                     , taxes_admin_row.modified
                     , taxes_admin_row.deleted );
      END LOOP a;

    -- Reporting Code
    FOR taxrep_row IN
      ( SELECT * FROM TABLE( CAST( XMLForm_TaxesReportCode( XMLType(insx)
      ) AS XMLForm_TaxReportCode_TT))
    ) LOOP <<repcode>>
        reportcode_section.EXTEND;
        reportcode_section(reportcode_section.LAST) := XMLForm_TaxesReporting
                     ( taxrep_row.id
                     , taxrep_row.rid
                     , taxrep_row.nkid
                     , taxrep_row.repcode
                     , taxrep_row.startdate
                     , taxrep_row.enddate
                     , taxrep_row.modified
                     , taxrep_row.deleted );
      END LOOP repcode;

    -- Additional Attributes

    FOR taxatt_row IN
      ( SELECT * FROM TABLE( CAST( XMLForm_TaxesAddAttrib( XMLType(insx)
      ) AS XMLForm_TaxAddAttr_TT))
    ) LOOP <<attrib>>
        attributes_section.EXTEND;
        attributes_section(attributes_section.LAST) := XMLForm_TaxesAttrib
                     ( taxatt_row.id
                     , taxatt_row.rid
                     , taxatt_row.nkid
                     , taxatt_row.attribute_id
                     , taxatt_row.aname
                     , taxatt_row.avalue
                     , taxatt_row.attrstartdate
                     , taxatt_row.attrenddate
                     , taxatt_row.modified
                     , taxatt_row.deleted );

      END LOOP attrib;

    -- Tags
    FOR itags IN (SELECT
        h.tag_id,
        h.deleted,
        h.status
    FROM XMLTABLE ('/jurisdictiontaxes/tag'
                        PASSING XMLTYPE(insx)
                        COLUMNS tag_id   NUMBER PATH 'tag_id',
                                deleted   NUMBER PATH 'deleted',
                                status   NUMBER PATH 'status'
								) h
          )
    LOOP
      tag_list.extend;
      tag_list( tag_list.last ):=xmlform_tags(
      3,
      taxdfn_row.nkid,
      taxdfn_row.enteredby,
      itags.tag_id,
      itags.deleted,
      0);
    END LOOP;


    -- Process form data
    process_form_detail(definition_section(definition_section.LAST) --::XMLForm_TaxesDefinition
                       ,thresholds_section         --::XMLForm_TaxThres_TT
                       ,reportcode_section         --::XMLForm_TaxReportCode_TT
                       ,admin_section              --::XMLForm_TaxAdminRecs_TT,
                       ,attributes_section         --::XMLForm_TaxAddAttr_TT
                       ,taxdfn_row.id
                       ,tag_list
                       ,rid_o
                       ,nkid_o);

  END LOOP mainloop;

  rid_o := TAX.get_current_revision(p_nkid=> nkid_o);
  --rid_o := TAX.get_revision(rid_i => rid_o, entered_by_i => l_n_enteredby);
/* 10/31: What are we looking for here? */
/* Only adding tags caused issues. New revision was created. */
 /*   if (l_wrk_rid<>definition_section(definition_section.LAST).rid or l_wrk_rid is null) then
      rid_o := TAX.get_revision(rid_i => rid_o, entered_by_i => l_n_enteredby);
    else
      rid_o := l_wrk_rid; -- current rid passed in the XML
    end if;*/

    success := 1;

  EXCEPTION
    WHEN others THEN
      ROLLBACK;
      success := 0;
      RAISE;

  END XMLProcess_Form_Taxes;


  /* ------------------------------------------------------------------------ */
  -- Process Form Detail
  PROCEDURE process_form_detail(definition_T IN XMLForm_TaxesDefine
                               ,thresholds_T IN XMLForm_TaxThres_TT
                               ,reportcode_T IN XMLForm_TaxReportCode_TT
                               ,adminirecs_T IN XMLForm_TaxAdminRecs_TT
                               ,addattribs_T IN XMLForm_TaxAddAttr_TT
                               ,id_o OUT NUMBER
                               ,tag_list IN xmlform_tags_tt
                               ,rid_o OUT NUMBER
                               ,nkid_o OUT NUMBER
  ) IS
    l_juris_pk          NUMBER := definition_T.id;
    l_juris_rid         NUMBER := definition_T.rid;
    l_juris_entered     NUMBER := definition_T.enteredby;

    l_thrs_pk           NUMBER;
    l_tax_outline_id    tax_outlines.id%TYPE := null;
    l_reps_pk           NUMBER;
    l_admins_pk         NUMBER;
    l_arrt_pk           NUMBER;

    cur_throutline      NUMBER := 0;
    createOutline       BOOLEAN := FALSE;

    -- Records update/insert
    Loc_Thresholds  Rec_Thresholds;
    Loc_Repcodes    Rec_ReportingCodes;
    Loc_Admins      Rec_Admins;
    Loc_AddAttr     Rec_AddAttr;

    dummyv NUMBER:=0;
    sx number:=0;
    sy number:=0;
    --
    -- DEV test for a flag for now;
    s_updated number:=0;
  BEGIN
      -- Tax Definition
      IF  (definition_T.modified = 1) THEN
        DS_Put_Definition(definition_T, id_o, rid_o, nkid_o);
      END IF;

      -- Thresholds
      FOR thrs in 1 .. thresholds_T.COUNT
      LOOP

        -- Outline + Threshold
        IF (thresholds_T(thrs).deleted = 1) THEN
            -- DEL
            DELETE FROM tax_definitions
            where tax_outline_id = thresholds_T(thrs).taxoutlineid;

            -- DEL outline if no tax_definitions are available.
            DELETE FROM tax_outlines
            WHERE id = thresholds_T(thrs).taxoutlineid;

        -- Threshold only
        ELSIF (thresholds_T(thrs).thDeleted = 1) THEN

            DELETE FROM tax_definitions
            where id = thresholds_T(thrs).id
            AND tax_outline_id = thresholds_T(thrs).taxoutlineid;

        ELSIF (thresholds_T(thrs).modified=1) then
            -- UPD or INS dataset
            Loc_Thresholds.id           := thresholds_T(thrs).id;
            Loc_Thresholds.rid          := thresholds_T(thrs).rid;
            Loc_Thresholds.nkid         := thresholds_T(thrs).nkid;
            Loc_Thresholds.startdate    := thresholds_T(thrs).startdate;
            Loc_Thresholds.enddate      := thresholds_T(thrs).enddate;
            Loc_Thresholds.taxoutlineid := thresholds_T(thrs).taxoutlineid;
            Loc_Thresholds.minthreshold := thresholds_T(thrs).minthreshold;
            Loc_Thresholds.maxlimit     := thresholds_T(thrs).maxlimit;
            Loc_Thresholds.thrvaluetype := thresholds_T(thrs).thrvaluetype;
            Loc_Thresholds.thrvalue     := thresholds_T(thrs).thrvalue;
            Loc_Thresholds.defertojuristaxid := thresholds_T(thrs).defertojuristaxid;
            Loc_Thresholds.currencyid   := thresholds_T(thrs).currencyid;
            Loc_Thresholds.modified     := thresholds_T(thrs).modified;
            Loc_Thresholds.deleted      := thresholds_T(thrs).deleted;
            Loc_Thresholds.calculation_structure_id := thresholds_T(thrs).defntype;


        if Loc_Thresholds.taxoutlineid is null then
            sx:= thresholds_T(thrs).throutlinerec;

              if (sx=sy) then
                Loc_Thresholds.taxoutlineid := l_tax_outline_id;
              else
                l_tax_outline_id := Loc_Thresholds.taxoutlineid;
              end if;
            sy:=sx;
        else
-- test to fail: what tax_outline_id
if (l_tax_outline_id <> Loc_Thresholds.taxoutlineid) then
 s_updated:=0;
DBMS_OUTPUT.Put_Line( '*'||l_tax_outline_id );
end if;
            l_tax_outline_id := Loc_Thresholds.taxoutlineid;
        end if;

            DS_Put_Threshold(Loc_Thresholds
                            ,id_o
                            ,l_juris_entered
                            ,l_tax_outline_id
                            ,definition_T.calculationstructureid
                            ,thrs
                            ,False
                            ,s_updated);
          END IF;

      END LOOP;

      -- Reporting code
      FOR repc in 1 .. reportcode_T.COUNT
      LOOP
          l_thrs_pk:=reportcode_T(repc).id;
          IF (reportcode_T(repc).deleted = 1)  THEN
              DELETE FROM tax_attributes
                where id = reportcode_T(repc).id
                and rid = reportcode_T(repc).rid
                and juris_tax_imposition_id = l_juris_pk;
          ELSIF (reportcode_T(repc).modified=1) THEN
            Loc_Repcodes.id           := reportcode_T(repc).id;
            Loc_Repcodes.rid          := reportcode_T(repc).rid;
            Loc_Repcodes.nkid         := reportcode_T(repc).nkid;
            Loc_Repcodes.repcode      := reportcode_T(repc).repcode;
            Loc_Repcodes.startdate    := reportcode_T(repc).startdate;
            Loc_Repcodes.enddate      := reportcode_T(repc).enddate;
            Loc_Repcodes.modified     := reportcode_T(repc).modified;
            Loc_Repcodes.deleted      := reportcode_T(repc).deleted;
            DS_Put_Reporting(Loc_Repcodes, id_o, l_juris_entered, repc);
          END IF;
      END LOOP;

      -- Administrators
      FOR admr in 1 .. adminirecs_T.COUNT
      LOOP
          l_thrs_pk:=adminirecs_T(admr).id;
          IF (adminirecs_T(admr).deleted = 1)  THEN
              -- DEL
              DELETE FROM tax_administrators
                where id = adminirecs_T(admr).id
                and rid = adminirecs_T(admr).rid
                and juris_tax_imposition_id = l_juris_pk;
          ELSIF (adminirecs_T(admr).modified=1) THEN
            -- UPD or INS dataset
            Loc_Admins.id               := adminirecs_T(admr).id;
            Loc_Admins.rid              := adminirecs_T(admr).rid;
            Loc_Admins.nkid             := adminirecs_T(admr).nkid;
            Loc_Admins.administrator_id := adminirecs_T(admr).administrator_id;
            Loc_Admins.admincollects    := adminirecs_T(admr).admincollects;
            Loc_Admins.admincollector   := adminirecs_T(admr).admincollector;
            Loc_Admins.admin_start      := adminirecs_T(admr).admin_start;
            Loc_Admins.admin_end        := adminirecs_T(admr).admin_end;
            Loc_Admins.modified         := adminirecs_T(admr).modified;
            Loc_Admins.deleted          := adminirecs_T(admr).deleted;
            DS_Put_Admins(Loc_Admins, id_o, l_juris_entered, admr);

            -- what do we really get here?
            Loc_Admins.admincollector:=null;
            Loc_Admins.admincollects:=null;

          END IF;
      END LOOP;

      -- Additional attributes
      FOR attr in 1 .. addattribs_T.COUNT
      LOOP
          l_thrs_pk:=addattribs_T(attr).id;
          IF (addattribs_T(attr).deleted = 1)  THEN
              -- DEL
              DELETE FROM tax_attributes
              WHERE id = addattribs_T(attr).id
              AND rid = addattribs_T(attr).rid
              AND juris_tax_imposition_id = l_juris_pk;
          ELSIF (addattribs_T(attr).modified=1) THEN
            -- UPD or INS dataset
            Loc_AddAttr.id           := addattribs_T(attr).id;
            Loc_AddAttr.rid          := addattribs_T(attr).rid;
            Loc_AddAttr.nkid         := addattribs_T(attr).nkid;
            Loc_AddAttr.attribute_id := addattribs_T(attr).attribute_id;
            Loc_AddAttr.aname        := addattribs_T(attr).aname;
            Loc_AddAttr.avalue       := addattribs_T(attr).avalue;
            Loc_AddAttr.attrStartDate:= addattribs_T(attr).attrStartDate;
            Loc_AddAttr.attrEndDate  := addattribs_T(attr).attrEndDate;
            Loc_AddAttr.modified     := addattribs_T(attr).modified;
            Loc_AddAttr.deleted      := addattribs_T(attr).deleted;
            DS_Put_Attribs(Loc_AddAttr, id_o, l_juris_entered, attr);
          END IF;
      END LOOP;

    -- Handle tags
    tags_registry.tags_entry(tag_list, nkid_o);

  END process_form_detail;


  -- Dataset Definition
  --
  --
  PROCEDURE DS_Put_Definition(definition_T IN XMLForm_TaxesDefine, id_o OUT number, rid_o OUT number, nkid_o OUT number)
  IS
    BEGIN
      IF definition_T.id IS NOT NULL THEN
        UPDATE juris_tax_impositions jtxi
        SET  jtxi.tax_description_id = definition_T.taxdescriptionid
            ,jtxi.revenue_purpose_id = definition_T.revenuepurpose
            ,jtxi.description = definition_T.description
            ,jtxi.start_date = definition_T.startdate
            ,jtxi.end_date = definition_T.enddate
            ,jtxi.entered_by = definition_T.enteredby
            ,jtxi.reference_code = definition_T.referencecode
        WHERE jtxi.id = definition_T.id
        RETURNING id, rid, nkid INTO id_o, rid_o, nkid_o;
      ELSE
        INSERT INTO juris_tax_impositions
        (jurisdiction_id, tax_description_id, reference_code, start_date,
         end_date, entered_by, description, revenue_purpose_id)
        VALUES(definition_T.jurisdiction_id, definition_T.taxdescriptionid,
        definition_T.referencecode, definition_T.startdate,
        definition_T.enddate, definition_T.enteredby,
        definition_T.description, definition_T.revenuepurpose)
        RETURNING id, rid, nkid INTO id_o, rid_o, nkid_o;
      END IF;

      EXCEPTION
      WHEN no_data_found THEN
          ROLLBACK;
          dbms_output.put_line(SQLCODE||' No records to update');
      WHEN OTHERS THEN
          ROLLBACK;
          RAISE;
  END DS_Put_Definition;


  /* ------------------------------------------------------------------------ */
  -- Dataset Threshold
  --
  --
  PROCEDURE DS_Put_Threshold( thresholds_T IN Rec_Thresholds
                             ,pJuris_tax_id IN NUMBER
                             ,pEnteredBy IN NUMBER
                             ,pTax_Outline_id IN OUT NUMBER
                             ,pCalculation_strc IN number
                             ,recno IN NUMBER
                             ,createOutline IN BOOLEAN
                             ,s_updated IN OUT NUMBER) IS
  BEGIN
      IF thresholds_T.id IS NOT NULL
         AND pTax_Outline_id IS NOT NULL THEN

DBMS_OUTPUT.Put_Line( 'Update Outlines'||pTax_Outline_id );

-- DEV 2/5/2015
-- How do we prevent the tax_outline to update multiple times now?
-- test variables
if s_updated = 0 then
          UPDATE tax_outlines
          SET start_date = thresholds_T.startdate
          , end_date = thresholds_T.enddate
          , calculation_structure_id = thresholds_T.calculation_structure_id
          , entered_by = pEnteredBy
          WHERE id = pTax_Outline_id;
-- or return into s_updated / id or a count?
s_updated:=1;
end if;


DBMS_OUTPUT.Put_Line( 'Upd Definitions'||thresholds_T.id );

          UPDATE tax_definitions
          SET min_threshold = thresholds_T.minthreshold
              ,max_limit = thresholds_T.maxlimit
              ,value_type = thresholds_T.thrvaluetype
              ,value = thresholds_T.thrvalue
              ,defer_to_juris_tax_id = thresholds_T.defertojuristaxid
              ,currency_id = thresholds_T.currencyid
              ,entered_by = pEnteredBy
          WHERE id = thresholds_T.id;

      ELSIF thresholds_T.id IS NULL
          AND pTax_Outline_id IS NULL
          AND pJuris_tax_id IS NOT NULL THEN
              -- Tax_Outlines
              INSERT INTO tax_outlines (
                          juris_tax_imposition_id,
                          calculation_structure_id,
                          start_date,
                          end_date,
                          entered_by
                          )
              VALUES (pjuris_tax_id,
                      thresholds_t.calculation_structure_id,
                      thresholds_t.startdate,
                      thresholds_t.enddate,
                      penteredby)
              RETURNING id
              INTO pTax_Outline_id;
      END IF;

      -- Insert Threshold items
     IF (pTax_Outline_id IS NOT NULL)
        AND thresholds_T.id IS NULL
        AND thresholds_T.modified =1 THEN
            INSERT INTO tax_definitions
            (tax_outline_id, min_threshold, max_limit, value_type, value,
             defer_to_juris_tax_id, currency_id, entered_by)
            VALUES
            (pTax_Outline_id, thresholds_T.minthreshold,
             thresholds_T.maxlimit, thresholds_T.thrvaluetype, thresholds_T.thrvalue,
             thresholds_T.defertojuristaxid, thresholds_T.currencyid, pEnteredBy);
      END IF;

      EXCEPTION
      WHEN no_data_found THEN
          ROLLBACK;
          dbms_output.put_line(SQLCODE||' No records to update');
      WHEN OTHERS THEN
          ROLLBACK;
          RAISE;

  END DS_Put_Threshold;

  /* ------------------------------------------------------------------------ */
  -- Dataset Reporting
  -- the attribute_id is set to 8
  PROCEDURE DS_Put_Reporting(reportcode_T IN Rec_ReportingCodes
                             ,pJuris_tax_id IN NUMBER
                             ,pEnteredBy IN NUMBER
                             ,recno IN number) is
  BEGIN
      IF reportcode_T.id IS NOT NULL AND pJuris_tax_id IS NOT NULL THEN
           -- attribute_id for reporting codes = 8
           Update tax_attributes
           Set start_date = reportcode_T.startdate
              ,end_date = reportcode_T.enddate
              ,value = reportcode_T.repcode
              ,entered_by = pEnteredBy
           where id = reportcode_T.id;
        ELSIF reportcode_T.id IS NULL AND pJuris_tax_id IS NOT NULL THEN
            Insert Into tax_attributes
            (juris_tax_imposition_id, start_date, end_date,
             entered_by, attribute_id, value)
            Values
            (pJuris_tax_id, reportcode_T.startdate,
             reportcode_T.enddate, pEnteredBy, 8, reportcode_T.repcode);
        END IF;

      EXCEPTION
      WHEN no_data_found THEN
          ROLLBACK;
          dbms_output.put_line(SQLCODE||' No records to update');
      WHEN OTHERS THEN
          ROLLBACK;
          RAISE;
  END;


  -- Dataset Administrators
  -- 9/11/13: simplified
  --
  PROCEDURE DS_Put_Admins(adminirecs_T IN Rec_Admins
                             ,pJuris_tax_id IN NUMBER
                             ,pEnteredBy IN NUMBER
                             ,recno IN number) is
  BEGIN
      IF (adminirecs_T.id IS NOT NULL) AND (pJuris_tax_id IS NOT NULL) THEN

--5/6 debug
DBMS_OUTPUT.Put_Line( 'Tax Admin Id:'||adminirecs_T.id );

           Update tax_administrators
           Set start_date = adminirecs_T.admin_start
              ,end_date = adminirecs_T.admin_end
              ,collector_id = nvl(adminirecs_T.admincollector,null)
              ,entered_by = pEnteredBy
           where id = adminirecs_T.id;
      ELSIF adminirecs_T.id IS NULL AND pJuris_tax_id IS NOT NULL THEN
           Insert Into tax_administrators
           (juris_tax_imposition_id, administrator_id, start_date
            , end_date
            , entered_by
            , collector_id)
           Values
           (pJuris_tax_id,
            adminirecs_T.administrator_id,
            nvl(adminirecs_T.admin_start, sysdate),
            nvl(adminirecs_T.admin_end, null),
            pEnteredBy,
            nvl(adminirecs_T.admincollector,null));
      END IF;

      EXCEPTION
      WHEN no_data_found THEN
          ROLLBACK;
          dbms_output.put_line(SQLCODE||' No records to update');
      WHEN OTHERS THEN
          ROLLBACK;
          RAISE;
  END;

  /* ------------------------------------------------------------------------ */
  -- Dataset Additional Attributes
  --
  --
  PROCEDURE DS_Put_Attribs(addattribs_T IN Rec_AddAttr
                             ,pJuris_tax_id IN NUMBER
                             ,pEnteredBy IN NUMBER
                             ,recno IN number) is
  BEGIN
      IF addattribs_T.id IS NOT NULL AND pJuris_tax_id IS NOT NULL THEN
           Update tax_attributes
           Set start_date = addattribs_T.attrStartDate
              ,end_date = addattribs_T.attrEndDate
              ,value = addattribs_T.avalue
              ,entered_by = pEnteredBy
           where id = addattribs_T.id;
        ELSIF addattribs_T.id IS NULL AND pJuris_tax_id IS NOT NULL THEN
            Insert Into tax_attributes
            (juris_tax_imposition_id, attribute_id, start_date
             , end_date, value, entered_by)
            Values
            (pJuris_tax_id,
             addattribs_T.attribute_id, addattribs_T.attrStartDate,
             addattribs_T.attrEndDate, addattribs_T.avalue, pEnteredBy);
        END IF;

      EXCEPTION
      WHEN no_data_found THEN
          ROLLBACK;
          dbms_output.put_line(SQLCODE||' No records to update');
      WHEN OTHERS THEN
          ROLLBACK;
          RAISE;
  END DS_Put_Attribs;

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
/*
PROCEDURE Log_Entries(pType IN NUMBER, sXML IN XMLType) IS
BEGIN
    --try except final
    INSERT INTO Log_XML_JTX values(pType, sXML, SYSDATE);
    -- {ToDo}    EXCEPTION
END;
*/
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  /** Main
   *
   * PHP CODE
   * $query =
   * "begin
   *    taxlaw_taxes.copy_juris_tax_imp(
   *    pJuris_tax_id => :JurisTaxId_ToCopy
   *    pStrSet => :listA
   *    pEntered_by => :user_id,
   *    rtnCopied => :returnCopiedNum
   *    );
   *    end;";
   *    $stmt = $dbh->prepare($query);
   *    ...->bindParam
   *    $stmt->bindParam(':listA', implode(',', $selectedBoxIDs));
  */

  -- Prep:
  /* When copy Juris_Tax store stats in table
  Send back ID of log record rtnCopied
  UI read table and display info
  */
  PROCEDURE tax_copy_log_p( log_id IN NUMBER,
                            cpy_juris_imp IN NUMBER,
                            cpy_to_juris_id IN NUMBER,
                            cpy_status IN NUMBER,
                            cpy_section IN NUMBER,
                            cpy_nkid IN number,
                            cpy_rid IN number,
                            to_juris_imp in number,
                            to_juris_imp_nkid in number,
                            to_juris_imp_rid in number
                          )
  IS
  BEGIN
    INSERT INTO tax_copy_log
    values( log_id
          , cpy_juris_imp
          , cpy_to_juris_id
          , cpy_status
          , cpy_section
          , sysdate
          , cpy_nkid
          , cpy_rid
          , to_juris_imp
          , to_juris_imp_nkid
          , to_juris_imp_rid
          );
  END;

  PROCEDURE Copy_Juris_Tax_Imp(pJuris_tax_id IN NUMBER
                              ,pStrSet IN VARCHAR2
                              ,pEntered_by IN NUMBER
                              ,rtnCopied OUT NUMBER)
  IS
    recFound NUMBER := 0;
    cpy_juris_tax_imp  juris_tax_impositions%ROWTYPE;
    cpy_thresholds     Rec_Thresholds;
    cpy_reportingcode  Rec_ReportingCodes;
    cpy_admins         Rec_Admins;
    cpy_AddAttr        Rec_AddAttr;

    new_juris_tax_imp_id juris_tax_impositions.id%TYPE;
    nkid_rtn juris_tax_impositions.nkid%TYPE;
    rid_rtn juris_tax_impositions.rid%TYPE;
    l_tax_outline_id     tax_outlines.id%TYPE;
    l_add_outline_id     tax_outlines.id%TYPE;
    cpyToJurisdiction    selected_string;

    TYPE xrec IS RECORD
    (vJI_ID NUMBER
    ,vJU_ID NUMBER
    ,nkid NUMBER
    ,rid NUMBER);
    TYPE ixTable IS TABLE OF xrec;
    ixOutData ixTable:=ixTable();
    i_tax_copy_log NUMBER;

    cnt_tax_description_id number := 0;
    nLog_J_nkid number;
    nLog_J_rid number;

    -- dataset for current tags
    TYPE tt_tax_tags IS TABLE OF juris_tax_imposition_tags%ROWTYPE;
    ds_tax_tags tt_tax_tags:=tt_tax_tags();

    -- dataset for new tags
    ds_new_tax_tags xmlform_tags_tt := xmlform_tags_tt();

    -- dataset for current tax applicability taxes
    ds_current_tax_applic tax_applicability_taxes%ROWType;

    jta_id number;
    jta_rid number;
    jta_nkid number;
    n_copy number;
    vRec number;
    defertojuristaxid number;

    -- Tax definition returns
    txdf_id number;
    txdf_nkid number;
    txdf_rtn number;
  BEGIN
    cpyToJurisdiction := fParseList(pStrSet);        -- Jurisdiction list
    rtnCopied := 0;                                  -- default 0 records copied

    -- Orig record set
    SELECT *
    INTO cpy_juris_tax_imp
    FROM juris_tax_impositions
    WHERE id = pJuris_tax_id;

    IF (SQL%FOUND) THEN
      -- Log actions: Get new ID for log info record per copy set
      i_tax_copy_log := tax_log_id_seq.nextval;

      FOR n IN 1 .. cpyToJurisdiction.COUNT
      LOOP
        SELECT COUNT(*) INTO recFound
                      FROM
                        juris_tax_impositions jimp
                      WHERE reference_code = cpy_juris_tax_imp.reference_code
                      AND jurisdiction_id IN (cpyToJurisdiction(n));

        -- JIRA CRAPP-366
        Select count(*) into cnt_tax_description_id
        from juris_tax_descriptions
        where tax_description_id = cpy_juris_tax_imp.tax_description_id
          and jurisdiction_id = cpyToJurisdiction(n);

        -- JIRA CRAPP-492
        -- Available revision for selected copy to jurisdiction list
        Select j.nkid, r.id rid --j.rid : changed j.rid to r.id as part of CRAPP-1902
          into nLog_J_nkid, nLog_J_rid
          from jurisdictions j
          /* commented to fix CRAPP-1902
            join jurisdiction_revisions r ON (r.nkid = j.nkid
                                        AND r.id >= j.rid
                                        AND r.id < NVL (j.next_rid, 999999999))*/
          join jurisdiction_revisions r on (r.nkid = j.nkid and r.next_rid is null) --added to fix CRAPP-1902
          where j.id = cpyToJurisdiction(n);
          --and r.status<>2; --commented to fix CRAPP-1902

        /* Create a new copy of the juris_tax_impositions */
        -- If the tax is already copied: no go
        -- If no imposition entry and the tax descriptor exists (Jurisdiction level): add
        IF recFound < 1 and cnt_tax_description_id > 0 THEN

            INSERT INTO juris_tax_impositions(
             jurisdiction_id
            ,tax_description_id
            ,revenue_purpose_id
            ,reference_code
            ,start_date
            ,end_date
            ,entered_by
            ,description
          )
            VALUES (
             cpyToJurisdiction(n)
            ,cpy_juris_tax_imp.tax_description_id
            ,cpy_juris_tax_imp.revenue_purpose_id
            ,cpy_juris_tax_imp.reference_code
            ,cpy_juris_tax_imp.start_date
            ,cpy_juris_tax_imp.end_date
            ,pEntered_by
            ,cpy_juris_tax_imp.description
            )
            RETURNING id, nkid, rid INTO new_juris_tax_imp_id, nkid_rtn, rid_rtn;
            ixOutData.Extend;
            ixOutData(ixOutData.Last).vJI_ID := new_juris_tax_imp_id;
            ixOutData(ixOutData.Last).vJU_ID := cpyToJurisdiction(n);
            ixOutData(ixOutData.Last).nkid := nkid_rtn;
            ixOutData(ixOutData.Last).rid := rid_rtn;

            -- Record copied: for Jurisdiction
            tax_copy_log_p(log_id=>i_tax_copy_log,
                     cpy_juris_imp=>pJuris_tax_id,
                     cpy_to_juris_id=>cpyToJurisdiction(n),
                     cpy_status=>1,
                     cpy_section=>1,
                     cpy_nkid=>nLog_J_nkid,
                     cpy_rid=>nLog_J_rid,
                     to_juris_imp=>new_juris_tax_imp_id,
                     to_juris_imp_nkid=>nkid_rtn,
                     to_juris_imp_rid=>rid_rtn
                    );

        -- Thresholds
        FOR taxoutlinecpy IN (
        SELECT id
              ,calculation_structure_id
              ,start_date
              ,end_date
        FROM tax_outlines
        WHERE juris_tax_imposition_id= pJuris_tax_id
        ) LOOP
          l_tax_outline_id := taxoutlinecpy.id;

          SELECT count(*) INTO recFound
            FROM tax_outlines
           WHERE juris_tax_imposition_id = new_juris_tax_imp_id
             AND calculation_structure_id = taxoutlinecpy.calculation_structure_id
             AND start_date = taxoutlinecpy.start_date;

              /* Create new outline */
              INSERT INTO tax_outlines(juris_tax_imposition_id
                ,calculation_structure_id
                ,start_date
                ,end_date
                ,entered_by) VALUES (
                 new_juris_tax_imp_id
                ,taxoutlinecpy.calculation_structure_id
                ,taxoutlinecpy.start_date
                ,taxoutlinecpy.end_date
                ,pEntered_by)
                RETURNING id INTO l_add_outline_id;

            -- Log
            tax_copy_log_p(log_id=>i_tax_copy_log,
                     cpy_juris_imp=>null,
                     cpy_to_juris_id=>null,
                     cpy_status=>1,
                     cpy_section=>2,
                     cpy_nkid=>null,
                     cpy_rid=>null,
                     to_juris_imp=>l_add_outline_id,
                     to_juris_imp_nkid=>null,
                     to_juris_imp_rid=>null
                    );

              -- Thresholditems Q/D
              FOR dsThresRec IN (
                SELECT txd.min_threshold
                      ,txd.max_limit
                      ,txd.value_type
                      ,txd.value
                      ,txd.defer_to_juris_tax_id
                      ,txd.currency_id
                FROM tax_definitions txd
               WHERE txd.tax_outline_id= l_tax_outline_id
            ) LOOP

                cpy_thresholds.id:=NULL;
                cpy_thresholds.minthreshold := dsThresRec.min_threshold;
                cpy_thresholds.maxlimit := dsThresRec.max_limit;
                cpy_thresholds.thrvaluetype := dsThresRec.value_type;
                cpy_thresholds.thrvalue := dsThresRec.value;
                cpy_thresholds.defertojuristaxid := dsThresRec.defer_to_juris_tax_id;
                cpy_thresholds.currencyid := dsThresRec.currency_id;

--
                if (cpy_thresholds.defertojuristaxid is not null) then
DBMS_OUTPUT.Put_Line('SELECT 1
                    ,(select lk.id
                    from juris_tax_impositions lk
                    where lk.jurisdiction_id='||cpyToJurisdiction(n)||'
                     and lk.reference_code = jti.reference_code) defer_to_juris_tax_id
                    into vRec, defertojuristaxid
                    FROM tax_definitions txd
                    JOIN juris_tax_impositions jti on (jti.id = txd.defer_to_juris_tax_id)
                    WHERE txd.tax_outline_id= '||l_tax_outline_id);

                    SELECT distinct 1
                    ,(select lk.id
                    from juris_tax_impositions lk
                    where lk.jurisdiction_id=cpyToJurisdiction(n)
                     and lk.reference_code = jti.reference_code) defer_to_juris_tax_id
                    into vRec, defertojuristaxid
                    FROM tax_definitions txd
                    JOIN juris_tax_impositions jti on (jti.id = txd.defer_to_juris_tax_id)
                    WHERE txd.tax_outline_id= l_tax_outline_id;
                    cpy_thresholds.defertojuristaxid:=defertojuristaxid;
                end if;

                INSERT INTO tax_definitions
                (tax_outline_id
                ,min_threshold
                ,max_limit
                ,value_type
                ,value
                ,defer_to_juris_tax_id
                ,currency_id
                ,entered_by)
                VALUES
                (l_add_outline_id
                ,cpy_thresholds.minthreshold
                ,cpy_thresholds.maxlimit
                ,cpy_thresholds.thrvaluetype
                ,cpy_thresholds.thrvalue
                ,cpy_thresholds.defertojuristaxid
                ,cpy_thresholds.currencyid
                ,pEntered_by)
                RETURNING id, nkid, rid INTO txdf_id, txdf_nkid, txdf_rtn;

            tax_copy_log_p(log_id=>i_tax_copy_log,
                     cpy_juris_imp=>null,
                     cpy_to_juris_id=>null,
                     cpy_status=>1,
                     cpy_section=>3,
                     cpy_nkid=>null,
                     cpy_rid=>null,
                     to_juris_imp=>txdf_id,
                     to_juris_imp_nkid=>txdf_nkid,
                     to_juris_imp_rid=>txdf_rtn
                    );

              END LOOP;

       END LOOP;

      -- Reporting Codes
      -- filter currently by the id from additional_attributes
        FOR dsRptRec IN (
        SELECT txa.start_date, txa.end_date, txa.value
        FROM tax_attributes txa
        WHERE txa.juris_tax_imposition_id= pJuris_tax_id
          AND txa.attribute_id
          IN ( SELECT id
               FROM additional_attributes
               WHERE NAME = 'Reporting Code' ))
        LOOP
            cpy_reportingcode.id:=NULL;
            cpy_reportingcode.repcode := dsRptRec.value;
            cpy_reportingcode.startdate := dsRptRec.start_date;
            cpy_reportingcode.enddate := dsRptRec.end_date;
            DS_Put_Reporting(cpy_reportingcode
                             ,new_juris_tax_imp_id
                             ,pEntered_By
                             ,0);

        END LOOP;

       -- Administrators
       --
       --
        FOR dsAdmRec IN (
        SELECT txa.administrator_id
        ,txa.start_date
        ,txa.end_date
        ,txa.rid
        ,txa.location_id
        ,txa.collector_id
        FROM tax_administrators txa
        WHERE txa.juris_tax_imposition_id= pJuris_tax_id)
        LOOP
            cpy_admins.id:=NULL;
            cpy_admins.rid :=dsAdmRec.rid;
            cpy_admins.administrator_id := dsAdmRec.administrator_id;
            cpy_admins.adm_location_id := dsAdmRec.location_id;
            cpy_admins.admin_start := dsAdmRec.start_date;
            cpy_admins.admin_end := dsAdmRec.end_date;
            cpy_admins.admincollector := dsAdmRec.collector_id;
            DS_Put_Admins(cpy_admins
                          ,new_juris_tax_imp_id
                          ,pEntered_By
                          ,0);
        END LOOP;

       -- Additional Attributes
       --
       --
        FOR dsAttRec IN (
        SELECT txa.start_date, txa.end_date, txa.value, txa.attribute_id
        FROM tax_attributes txa
        WHERE txa.juris_tax_imposition_id= pJuris_tax_id
          AND txa.attribute_id NOT IN
          (SELECT id FROM additional_attributes WHERE NAME = 'Reporting Code'))
        LOOP
            cpy_AddAttr.id:=NULL;
            cpy_AddAttr.attribute_id := dsAttRec.attribute_id;
            cpy_AddAttr.attrStartDate := dsAttRec.start_date;
            cpy_AddAttr.attrEndDate := dsAttRec.end_date;
            cpy_AddAttr.avalue := dsAttRec.value;
            DS_Put_Attribs(cpy_AddAttr
                           ,new_juris_tax_imp_id
                           ,pEntered_By
                           ,0);
        END LOOP;

       -- TAGS
        Select *
        Bulk Collect Into ds_tax_tags
             From juris_tax_imposition_tags tg
        Where tg.ref_nkid =
         (SELECT max(j.nkid) mxi
          FROM jurisdiction_tax_revisions r
          join juris_tax_impositions j on (j.nkid = r.nkid)
          where r.id = cpy_juris_tax_imp.rid
          and j.rid <= r.id );

        IF (ds_tax_tags.count > 0) then
            FOR lp IN ds_tax_tags.first..ds_tax_tags.last
            LOOP
              ds_new_tax_tags.extend;
              ds_new_tax_tags( ds_new_tax_tags.last ):=xmlform_tags(3,
              ds_tax_tags(lp).ref_nkid,
              pEntered_by,
              ds_tax_tags(lp).tag_id,
              0,
              0);
            END LOOP;
            tags_registry.tags_entry(ds_new_tax_tags, nkid_rtn);
        End if;

       /* ------------------------------------------------------------------- */

       ELSE

        if cnt_tax_description_id < 1 then
          n_copy := -1;  -- no tax categorization
        elsif (recFound > 0) then
          n_copy := 0; -- reference already exists
        end if;

        tax_copy_log_p(log_id=>i_tax_copy_log,
                     cpy_juris_imp=>pJuris_tax_id,
                     cpy_to_juris_id=>cpyToJurisdiction(n),
                     cpy_status=>n_copy,
                     cpy_section=>1,
                     cpy_nkid=>nLog_J_nkid,
                     cpy_rid=>nLog_J_rid,
                     to_juris_imp=>null,
                     to_juris_imp_nkid=>null,
                     to_juris_imp_rid=>null
                    );

       END IF;

      END LOOP;
      -- end {recfound}
         rtnCopied:=i_tax_copy_log; -- success
DBMS_OUTPUT.Put_Line( '<-- copy tax end' );

    ELSIF ( SQL%NOTFOUND ) THEN
      -- either 'errorlog' or just info to application?
      dbms_output.put_line( 'No data found.' );
      rtnCopied:=0;
    END IF;

  END Copy_Juris_Tax_Imp;


  PROCEDURE delete_revision(revision_id_i IN NUMBER, deleted_by_i IN NUMBER, success_o OUT NUMBER)
  IS
        l_rid NUMBER := revision_id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_juris_pk NUMBER;
        l_status NUMBER;
    BEGIN
      success_o := 0;
      --Get status to validate that it's a deleteable record
      --Get revision ID to delete all depedent records by
      SELECT status
      INTO l_status
      FROM jurisdiction_tax_revisions
      where id = l_rid;

        IF (l_status = 0) THEN
            --Remove dependent Attributes
            --Reset prior revisions to current
            UPDATE tax_attributes ja
            SET ja.next_rid = NULL
            WHERE ja.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'TAX_ATTRIBUTES', ja.id
                FROM tax_attributes ja
                WHERE ja.rid = l_rid
            );

            DELETE FROM tax_attributes ja
            WHERE ja.rid = l_rid;

            -- Remove Tax_definitions
            UPDATE Tax_Definitions td
            SET td.next_rid = NULL
            WHERE td.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'TAX_DEFINITIONS', td.id
                FROM Tax_Definitions td
                WHERE td.rid = l_rid
            );

            DELETE FROM Tax_Definitions td
            WHERE td.rid = l_rid;

            --Remove dependent Tax_Outline
            --Reset prior revisions to current
            UPDATE tax_outlines td
            SET td.next_rid = NULL
            WHERE td.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'TAX_OUTLINES', td.id
                FROM tax_outlines td
                WHERE td.rid = l_rid
            );

            DELETE FROM tax_outlines td
            WHERE td.rid = l_rid;

            --Remove dependent Tax mappings
            --Reset prior revisions to current
            UPDATE tax_administrators ja
            SET ja.next_rid = NULL
            WHERE ja.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'TAX_ADMINISTRATORS', ja.id
                FROM tax_administrators ja
                WHERE ja.rid = l_rid
            );

            DELETE FROM tax_administrators ta
            WHERE ta.rid = l_rid;

            --Remove record
            UPDATE juris_tax_impositions ji
            SET ji.next_rid = NULL
            WHERE ji.next_rid = l_rid;

            UPDATE jurisdiction_tax_revisions ji
            SET ji.next_rid = NULL
            WHERE ji.next_rid = l_rid;

            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) (
                SELECT 'JURIS_TAX_IMPOSITIONS', ja.id
                FROM juris_tax_impositions ja
                WHERE ja.rid = l_rid
            );

            DELETE FROM juris_tax_impositions ji WHERE ji.rid = l_rid;

            --Remove Revision record
            --preserve ID's for logging
            INSERT INTO tmp_delete (table_name, primary_key) VALUES ('JURISDICTION_TAX_REVISIONS',l_rid);
            DELETE FROM juris_tax_chg_logs jc WHERE jc.rid = l_rid;
            DELETE FROM jurisdiction_tax_revisions jr WHERE jr.id = l_rid;

            INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
                SELECT table_name, primary_key, l_deleted_by
                FROM tmp_delete
                                -- where ?
            );

          COMMIT;
          success_o := 1;
        ELSE
            RAISE errnums.cannot_delete_record;
        END IF;

    EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_go(errnums.en_cannot_delete_record,'Record could not be deleted because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_stop(SQLCODE,SQLERRM);

    END delete_revision;

  PROCEDURE delete_revision(resetAll IN Number,
            revision_id_i IN NUMBER,
            deleted_by_i IN NUMBER,
            success_o OUT NUMBER)
  IS
        l_rid NUMBER := revision_id_i;
        l_deleted_by NUMBER := deleted_by_i;
        l_juris_pk NUMBER;
        l_status NUMBER;
        l_cit_count number;
        
        l_stat_cnt NUMBER := 0; -- crapp-2749
    BEGIN
      success_o := 0;

        if resetAll = 1 then
          SELECT COUNT(status)
          INTO l_stat_cnt
          FROM jurisdiction_tax_revisions
          WHERE id = l_rid;

          IF l_stat_cnt > 0 THEN -- crapp-2749 
              SELECT status
              INTO l_status
              FROM jurisdiction_tax_revisions
              WHERE id = l_rid;

              IF (l_status = 1) THEN
                reset_status(revision_id_i=>revision_id_i, reset_by_i=>deleted_by_i, success_o=>success_o);
                -- {{Any option if failed?}}
              End If; -- status

              Delete From juris_tax_chg_vlds vld
              Where vld.juris_tax_chg_log_id in
                  (Select id From juris_tax_chg_logs
                    Where rid=l_rid);
              IF SQL%NOTFOUND THEN
                DBMS_OUTPUT.PUT_LINE('No validations to remove');
              END IF;
          END IF; -- l_stat_cnt
        end if; -- resetAll

        SELECT COUNT(status)
        INTO l_stat_cnt
        FROM jurisdiction_tax_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN -- crapp-2749
            SELECT status
            INTO l_status
            FROM jurisdiction_tax_revisions
            where id = l_rid;

            IF (l_status = 0) THEN
                --Remove dependent Attributes
                --Reset prior revisions to current
                UPDATE tax_attributes ja
                SET ja.next_rid = NULL
                WHERE ja.next_rid = l_rid;

                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'TAX_ATTRIBUTES', ja.id
                    FROM tax_attributes ja
                    WHERE ja.rid = l_rid
                );

                DELETE FROM tax_attributes ja
                WHERE ja.rid = l_rid;

                -- Remove Tax_definitions
                UPDATE Tax_Definitions td
                SET td.next_rid = NULL
                WHERE td.next_rid = l_rid;

                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'TAX_DEFINITIONS', td.id
                    FROM Tax_Definitions td
                    WHERE td.rid = l_rid
                );

                DELETE FROM Tax_Definitions td
                WHERE td.rid = l_rid;

                --Remove dependent Tax_Outline
                --Reset prior revisions to current
                UPDATE tax_outlines td
                SET td.next_rid = NULL
                WHERE td.next_rid = l_rid;

                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'TAX_OUTLINES', td.id
                    FROM tax_outlines td
                    WHERE td.rid = l_rid
                );

                DELETE FROM tax_outlines td
                WHERE td.rid = l_rid;

                --Remove dependent Tax mappings
                --Reset prior revisions to current
                UPDATE tax_administrators ja
                SET ja.next_rid = NULL
                WHERE ja.next_rid = l_rid;

                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'TAX_ADMINISTRATORS', ja.id
                    FROM tax_administrators ja
                    WHERE ja.rid = l_rid
                );

                DELETE FROM tax_administrators ta
                WHERE ta.rid = l_rid;

                --Remove record
                UPDATE juris_tax_impositions ji
                SET ji.next_rid = NULL
                WHERE ji.next_rid = l_rid;

                UPDATE jurisdiction_tax_revisions ji
                SET ji.next_rid = NULL
                WHERE ji.next_rid = l_rid;

                --preserve ID's for logging
                INSERT INTO tmp_delete (table_name, primary_key) (
                    SELECT 'JURIS_TAX_IMPOSITIONS', ja.id
                    FROM juris_tax_impositions ja
                    WHERE ja.rid = l_rid
                );

                DELETE FROM juris_tax_impositions ji WHERE ji.rid = l_rid;

              if resetAll = 1 then
                -- Check juris_chg_cits
                -- Simple count instead of Exception
                Select count(*) INTO l_cit_count
                  From juris_tax_chg_cits cit where cit.juris_tax_chg_log_id
                  IN (Select id From juris_tax_chg_logs jc where jc.rid = l_rid);
                If l_cit_count > 0 Then
                   DELETE FROM juris_tax_chg_cits cit where cit.juris_tax_chg_log_id
                       IN (Select id From juris_tax_chg_logs jc where jc.rid = l_rid);
                End if;
              end if;

              --Remove Revision record
              --preserve ID's for logging
              INSERT INTO tmp_delete (table_name, primary_key) VALUES ('JURISDICTION_TAX_REVISIONS',l_rid);
              DELETE FROM juris_tax_chg_logs jc WHERE jc.rid = l_rid;
              DELETE FROM jurisdiction_tax_revisions jr WHERE jr.id = l_rid;

              INSERT INTO delete_logs (table_name, primary_key, deleted_by) (
                     SELECT table_name, primary_key, l_deleted_by
                     FROM tmp_delete);

              COMMIT;
              success_o := 1;
            ELSE
                RAISE errnums.cannot_delete_record;
            END IF;
        ELSE
            success_o := 1; -- returning success since there was nothing to remove
        END IF; -- l_stat_cnt

    EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_go(errnums.en_cannot_delete_record,'Record could not be deleted because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            success_o := 0;
            errlogger.report_and_stop(SQLCODE,SQLERRM);

    END delete_revision;

    /*
    *  Reset Status
    */
    PROCEDURE reset_status
       (
       revision_id_i IN NUMBER,
       reset_by_i IN NUMBER,
       success_o OUT NUMBER
       )
       IS
        l_rid NUMBER := revision_id_i;
        l_reset_by NUMBER := reset_by_i;
        l_juris_pk NUMBER;
        l_status NUMBER;
        setVal NUMBER := 0;
        
        l_stat_cnt NUMBER := 0; -- crapp-2749
    BEGIN
        success_o := 0;
        --Get status to validate that it's a record that can be reset

        SELECT COUNT(status)
        INTO l_stat_cnt
        FROM jurisdiction_tax_revisions
        WHERE id = l_rid;

        IF l_stat_cnt > 0 THEN
            SELECT status
            INTO l_status
            FROM jurisdiction_tax_revisions
            WHERE id = l_rid;

            IF (l_status = 1) THEN

                UPDATE tax_attributes ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                UPDATE tax_definitions ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                UPDATE tax_outlines ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                UPDATE tax_administrators ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                UPDATE juris_tax_impositions ji
                SET status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.rid = l_rid;

                --Reset status
                UPDATE jurisdiction_tax_revisions ji
                SET ji.status = setVal,
                ji.entered_By = l_reset_by
                WHERE ji.id = l_rid;

                COMMIT;
                success_o := 1;
            ELSE
                RAISE errnums.cannot_delete_record;
            END IF;
        END IF; -- l_stat_cnt

    EXCEPTION
        WHEN errnums.cannot_delete_record THEN
            ROLLBACK;
            errlogger.report_and_stop(errnums.en_cannot_delete_record,'Record status could not be changed because it has already been published.');
        WHEN others THEN
            ROLLBACK;
            errlogger.report_and_stop(SQLCODE,SQLERRM);
    END reset_status;

  /** COPY-UPDATE
   *  Update multiple
   *  Moved to Update Multiple Package
   *  *** DEVELOPMENT VERSION 6/25/14 ***
   */
  PROCEDURE bulk_upd_tax_select(p_tax_id IN juris_tax_impositions.id%type,
            change_class in number,
            p_ref OUT SYS_REFCURSOR)
  IS
    row_juris_tax_imp  juris_tax_impositions_v%ROWTYPE;
    cpy_thresholds     Rec_Thresholds;
    cpy_reportingcode  Rec_ReportingCodes;
    cpy_admins         Rec_Admins;
    cpy_addattr        Rec_AddAttr;
    change_v           varchar2(256);
  BEGIN
    -- Base record
    -- p_tax_id is known in the form (user selected juris, tax reference, revision)
    -- Get current record (orig record - keep this one)
    Select jti.id, jti.nkid, jti.rid, jti.next_rid, jti.juris_tax_entity_rid,
           jti.juris_tax_next_rid, jti.jurisdiction_id, jti.jurisdiction_nkid,
           jti.jurisdiction_rid, jti.tax_description_id, jti.reference_code,
           jti.start_date, jti.end_date, jti.description, jti.status,
           jti.status_modified_date, jti.entered_by, jti.entered_date,
           jti.revenue_purpose_id, jti.is_current
      into row_juris_tax_imp
      from juris_tax_impositions_v jti
     where id = p_tax_id;

    -- possible check for valid selection here (status?)
    if row_juris_tax_imp.status<>STATUS_PUBLISHED then

    /* search criterias? Where does it come from and how does it come across?
       Open p_ref For ''
        USING p_tax_id;*/
    change_v := frmChangeSection(change_class);

    --Open p_ref for
    DBMS_OUTPUT.Put_Line( '(Select *
    juris_tax_impositions_v txv '||change_v||
    ') a join
    -- Table Data
    select /*+ FIRST_ROWS(10)*/
    ''Valid to change'' blkEditInfo, 3 SOrder,
    txo.id,
    txo.calculation_structure_id,
    txo.start_date txo_start_date,
    txo.end_date txo_end_date,
    txo.status,
    txd.id txd_id,
    txd.value_type,
    txd.value,
    txv.id txi_id,
    txv.nkid txi_nkid,
    txv.rid txi_rid,
    txv.tax_description_id,
    txv.reference_code,
    txa.administrator_id,
    txat.attribute_id
    from juris_tax_impositions_v txv
    join tax_attributes txat on (txat.juris_tax_imposition_id = txv.id)
    join tax_administrators txa on (txa.juris_tax_imposition_id = txv.id)
    join tax_outlines txo on (txo.juris_tax_imposition_id = txv.id)
    join tax_definitions txd on (txd.tax_outline_id = txo.id) ) b
    on (
    -- add/remove crit. UI?
    b.reference_code = a.reference_code
    and b.value_type = a.value_type
    -- and b.value <> r/ new value
    and b.calculation_structure_id = a.calculation_structure_id
    --> should they have the same start_date?
    --  and b.txo_start_date = a.txo_start_date
    and b.txo_start_date <= a.txo_end_date
    -- and b.txo_start_date <= to_date(''20140531'',''yyyymmdd'') filter in UI?
    and b.txo_end_date is null
    and b.tax_description_id = a.tax_description_id
    -- other? b.administrator_id <> a.administrator_id OR!
    )
    WHERE a.id = :impId');
  -- USING row_juris_tax_imp.reference_code,
  -- row_juris_tax_imp.tax_description_id

    -- pipe records of "valid to change"

    -- 2. get changed info
    -- + list of validated records (checked) in XML
    --> 3. upd/insert

    end if;
  END;

  -- Bulk [Update / Add] dataset from form
  -- (Moved to the Update Multiple package)
  Procedure blk_upd_tax (pUpdFormXML IN CLOB, success OUT number, log_id OUT number)
  is
  begin
    null;
  end;


END taxlaw_taxes;
/