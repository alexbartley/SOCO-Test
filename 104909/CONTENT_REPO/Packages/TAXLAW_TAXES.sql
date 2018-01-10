CREATE OR REPLACE PACKAGE content_repo."TAXLAW_TAXES" IS
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
-- -----------------------------------------------------------------
  xmlRoot varchar2(32) :='jurisdictiontaxes';  -- XML root tag

  TYPE Rec_Thresholds IS RECORD
  ( id            NUMBER
  , rid           NUMBER
  , taxoutlineid  NUMBER
  , nkid          NUMBER
  , startdate DATE
  , enddate DATE
  , minthreshold NUMBER
  , maxlimit     NUMBER
  , thrvaluetype VARCHAR2(15)
  , thrvalue     NUMBER
  , defertojuristaxid NUMBER
  , currencyid NUMBER
  , modified      NUMBER
  , deleted       NUMBER
  , throutlinerec NUMBER
  , calculation_structure_id number);

  TYPE Rec_ReportingCodes IS RECORD
  ( id NUMBER
  , rid NUMBER
  , nkid NUMBER
  , repcode VARCHAR2(100)
  , startdate DATE
  , enddate DATE
  , modified NUMBER
  , deleted NUMBER);

  TYPE Rec_Admins IS RECORD
  ( id NUMBER
  , rid NUMBER
  , nkid NUMBER
  , administrator_id NUMBER
  , adm_location_id number
  , admincollects number
  , admincollector varchar2(100)
  , admin_start date
  , admin_end date
  , modified number
  , deleted NUMBER);

  TYPE Rec_AddAttr IS RECORD
  ( id NUMBER
  , rid NUMBER
  , nkid NUMBER
  , attribute_id NUMBER
  , aname  VARCHAR2(100)
  , avalue VARCHAR2(1000)
  , attrStartDate DATE
  , attrEndDate DATE
  , modified NUMBER
  , deleted NUMBER);

  TYPE selected_string IS TABLE OF VARCHAR2(256) INDEX BY BINARY_INTEGER;

  -- Parse array -> table
  -- (Build a table from a list to be copied)
  FUNCTION fParseList(pList VARCHAR2) RETURN selected_string;

  FUNCTION XMLForm_TaxesDefinition(form_xml_i IN SYS.XMLType)
           RETURN XMLForm_TaxDefn_TT PIPELINED;
  FUNCTION XMLForm_TaxesThresholds(form_xml_i IN XMLType)
           RETURN XMLForm_TaxThres_TT PIPELINED;
  FUNCTION XMLForm_TaxesReportCode(form_xml_i IN XMLType)
           RETURN XMLForm_TaxReportCode_TT PIPELINED;
  FUNCTION XMLForm_TaxesAdminRecs(form_xml_i IN XMLType)
           RETURN XMLForm_TaxAdminRecs_TT PIPELINED;
  FUNCTION XMLForm_TaxesAddAttrib(form_xml_i IN XMLType)
           RETURN XMLForm_TaxAddAttr_TT PIPELINED;

  -- Main
  PROCEDURE XMLProcess_Form_Taxes(insx IN CLOB, success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER);
  -- reminder: things like AUDIT INSERT ON tables WHENEVER NOT SUCCESSFUL

  PROCEDURE process_form_detail(definition_T IN XMLForm_TaxesDefine
                               ,thresholds_T IN XMLForm_TaxThres_TT
                               ,reportcode_T IN XMLForm_TaxReportCode_TT
                               ,adminirecs_T IN XMLForm_TaxAdminRecs_TT
                               ,addattribs_T IN XMLForm_TaxAddAttr_TT
                               ,id_o OUT NUMBER
                               ,tag_list IN xmlform_tags_tt
                               ,rid_o OUT NUMBER
                               ,nkid_o OUT NUMBER
                               );

  PROCEDURE DS_Put_Definition(definition_T IN XMLForm_TaxesDefine
                              ,id_o OUT NUMBER
                              ,rid_o OUT NUMBER
                              ,nkid_o OUT NUMBER);

  PROCEDURE DS_Put_Threshold(thresholds_T IN Rec_Thresholds
                             ,pJuris_tax_id IN NUMBER
                             ,pEnteredBy IN NUMBER
                             ,pTax_Outline_id IN OUT NUMBER
                             ,pCalculation_strc IN number
                             ,recno IN NUMBER
                             ,createOutline BOOLEAN
                             ,s_updated IN OUT number);

  PROCEDURE DS_Put_Reporting(reportcode_T IN Rec_ReportingCodes
                             ,pJuris_tax_id IN NUMBER
                             ,pEnteredBy IN NUMBER
                             ,recno IN number);

  PROCEDURE DS_Put_Admins(adminirecs_T IN Rec_Admins
                             ,pJuris_tax_id IN NUMBER
                             ,pEnteredBy IN NUMBER
                             ,recno IN number);

  PROCEDURE DS_Put_Attribs(addattribs_T IN Rec_AddAttr
                             ,pJuris_tax_id IN NUMBER
                             ,pEnteredBy IN NUMBER
                             ,recno IN number);

  PROCEDURE delete_revision(revision_id_i IN NUMBER, deleted_by_i IN NUMBER, success_o OUT NUMBER);
  -- Overloaded: delete_revision, reset, remove attachments
  PROCEDURE delete_revision(resetAll IN Number,
            revision_id_i IN NUMBER,
            deleted_by_i IN NUMBER,
            success_o OUT NUMBER);

  -- COPY
  /**
   * Currently based on pJuris_tax_id and a string from PHP
   * pStrSet = jurisdiction id, 'n,n,n...n'
   * selected_string becomes a table of the id list
   */
  PROCEDURE Copy_Juris_Tax_Imp(pJuris_tax_id IN NUMBER
                              ,pStrSet IN VARCHAR2
                              ,pEntered_by IN NUMBER
                              ,rtnCopied OUT NUMBER);


  PROCEDURE bulk_upd_tax_select(p_tax_id IN juris_tax_impositions.id%type,
            change_class in number,
                                p_ref               OUT SYS_REFCURSOR);

  PROCEDURE blk_upd_tax (pUpdFormXML IN CLOB, success OUT number, log_id OUT number);

  PROCEDURE reset_status
       (
       revision_id_i IN NUMBER,
       reset_by_i IN NUMBER,
       success_o OUT NUMBER
       );

END taxlaw_taxes;
/