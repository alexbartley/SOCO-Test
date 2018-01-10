CREATE OR REPLACE PACKAGE content_repo.JURISDICTION
IS
-- *****************************************************************************
-- Description: Handle operations related to managing jurisdictions
-- *****************************************************************************
-- 06/23/2015 : CRAPP-1729
-- 08/30/2016 : CRAPP-2987
--              CRAPP-2021
-- 08/30/2016 : CRAPP-2997
-- 03/21/2017 : CRAPP-3264 set attribute start date to Jurisdiction start date if empty
-- 03/30/2017 : test of CURRENT and END DATE for copy CRAPP-3264
-- 05/09/2017 : CRAPP-3549 DB work for Angular conversion - new xml
-- 06/05/2017 : CRAPP-3627 DB work to store Jurisdiction Advanced
-- 08/07/2017 : CRAPP-3898 Copy Messages
-- 05/08/2017 : CRAPP-3689 Datamodel changes to store Jurisdiction Messages

  -- Development 201705
  FUNCTION xml_jurisHeader(form_xml_i IN sys.XMLType) return XMLForm_Juri_TT PIPELINED;
  FUNCTION xml_jurisAttributes (form_xml_i IN SYS.XMLTYPE) RETURN xmlform_attr_tt PIPELINED;
  FUNCTION xml_jurisContributions (form_xml_i IN SYS.XMLTYPE) RETURN xmlform_contrib_tt PIPELINED;
  FUNCTION xml_jurisTaxCategories(form_xml_i IN sys.XMLType) return XMLForm_TaxDesc_TT PIPELINED;
  PROCEDURE Process_Form(sx IN CLOB, update_success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER);

  -- Current
  FUNCTION XMLForm_Juris1(form_xml_i IN sys.XMLType) return XMLForm_Juri_TT PIPELINED;
  FUNCTION XMLForm_Attr1(form_xml_i IN sys.XMLType) return XMLForm_Attr_TT PIPELINED;
  FUNCTION XMLForm_TaxDesc(form_xml_i IN sys.XMLType) return XMLForm_TaxDesc_TT PIPELINED;
  FUNCTION XMLForm_contribution(form_xml_i IN sys.XMLType) return XMLForm_contrib_TT PIPELINED;

  PROCEDURE XMLProcess_Form_Juris1(sx IN CLOB, update_success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER);
  PROCEDURE update_full (
    details_i IN XMLFormJurisdiction,
    att_list_i IN XMLForm_Attr_TT,
    contrib_list_i IN XMLForm_contrib_TT,
    td_list_i IN XMLForm_TaxDesc_TT,
    tag_list in xmlform_tags_tt,
	option_list_i IN XMLFORM_OPTION_TT,
    logicmapng_list_i IN XMLFORM_LOGICMAPNG_TT,
    message_list_i     IN     xmlform_error_messages_tt,
    nkid_o OUT NUMBER,
    rid_o OUT NUMBER
  );

  PROCEDURE update_record (
    id_io IN OUT NUMBER,
    official_name_i IN VARCHAR2,
    description_i IN VARCHAR2,
    start_date_i IN DATE,
    end_date_i IN DATE,
    currency_id_i IN NUMBER,
    loc_category_id_i IN NUMBER,
    entered_by_i IN NUMBER,
    nkid_o OUT NUMBER,
    rid_o OUT NUMBER,
    default_admin_i in number,
    deleted_header in number,
    juristypeid_i  IN     NUMBER
  );

  /*
    Copy Jurisdiction (include tax or taxability)
    N - No Tax Copy (this was the default)
    A - All (Include Historical)
    C - Current Only
  */
  PROCEDURE copy (sx in out clob);

  PROCEDURE delete_revision (
    revision_id_i IN NUMBER,
    deleted_by_i IN NUMBER,
    success_o OUT NUMBER
  );

  -- delete_revision, reset, remove attachments
  PROCEDURE delete_revision
       (
       resetAll IN Number,
       revision_id_i IN NUMBER,
       deleted_by_i IN NUMBER,
       success_o OUT NUMBER
       );


  PROCEDURE update_attribute (
    id_io IN OUT NUMBER,
    jurisdiction_id_i IN NUMBER,
    attribute_id_i IN NUMBER,
    value_i IN VARCHAR2,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER
  );

  PROCEDURE update_tax_description (
    id_io IN OUT NUMBER,
    jurisdiction_id_i IN NUMBER,
    tax_description_id_i IN NUMBER,
    tran_type_id_i IN NUMBER,
    tax_type_id_i IN NUMBER,
    spec_app_type_id_i IN NUMBER,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER
  );

  FUNCTION add_tax_description (
    tran_type_id_i IN NUMBER,
    tax_type_id_i IN NUMBER,
    spec_app_type_id_i IN NUMBER,
    entered_by_i IN NUMBER
  ) RETURN NUMBER;

  PROCEDURE remove_tax_description (
    id_i IN NUMBER,
    deleted_by_i IN NUMBER,
    jurisdiction_id_i in NUMBER,
    pDelete OUT number
  );
  PROCEDURE remove_attribute (id_i IN NUMBER, deleted_by_i IN NUMBER);

  FUNCTION get_revision (
    entity_id_io IN OUT NUMBER,
    entity_nkid_i IN NUMBER,
    entered_by_i IN NUMBER
  ) RETURN NUMBER;

  FUNCTION get_revision (
    rid_i IN NUMBER,
    entered_by_i IN NUMBER
  ) RETURN NUMBER;

  PROCEDURE reset_status (revision_id_i IN NUMBER,
                          reset_by_i IN NUMBER,
                          success_o OUT NUMBER);

  FUNCTION get_current_revision (p_nkid IN NUMBER) RETURN NUMBER;

  PROCEDURE unique_check(name_i IN VARCHAR2, nkid_i IN NUMBER);
  PROCEDURE remove_juris_header (pNkid IN NUMBER, pDeletedBy IN NUMBER, pJurisdictionId IN number, success_o OUT NUMBER);

  -- Development 201706 (CRAPP-3627)
  FUNCTION xml_jurisoptions (form_xml_i IN SYS.XMLTYPE) RETURN xmlform_option_tt PIPELINED;
  FUNCTION xml_jurislogicmapng (form_xml_i IN SYS.XMLTYPE) RETURN xmlform_logicmapng_tt PIPELINED;
  FUNCTION xml_juriserrormessages (form_xml_i IN SYS.XMLTYPE) RETURN xmlform_error_messages_tt PIPELINED;

  PROCEDURE update_jurisoptions (
    id_io IN OUT NUMBER,
    jurisdiction_id_i IN NUMBER,
	name_id_i IN VARCHAR2,
	value_id_i IN VARCHAR2,
	condition_id_i IN VARCHAR2,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER
  );

  PROCEDURE update_jurislogicmapng (
    id_io IN OUT NUMBER,
    jurisdiction_id_i IN NUMBER,
	juris_logic_group_id_i IN NUMBER,
	process_order_i IN NUMBER,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER
  );

   PROCEDURE update_juris_error_messages ( 
	 id_io               	IN OUT NUMBER,
     jurisdiction_id_i       IN     NUMBER,
     severity_id_i 			IN NUMBER,
     error_msg_i				IN VARCHAR2,
     description_id_i 		IN VARCHAR2,
      start_date_i IN DATE,
       end_date_i IN DATE,
     entered_by_i            IN NUMBER
     );


 PROCEDURE remove_jurisoptions (id_i IN NUMBER, deleted_by_i IN NUMBER);

 PROCEDURE remove_jurislogicmapng (id_i IN NUMBER, deleted_by_i IN NUMBER);

  PROCEDURE remove_juris_error_messages (id_i IN NUMBER, deleted_by_i IN NUMBER);

END JURISDICTION;
/