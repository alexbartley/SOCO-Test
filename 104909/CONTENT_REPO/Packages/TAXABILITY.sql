CREATE OR REPLACE PACKAGE content_repo.taxability
IS
--
-- TDR Taxabilities
--
-- MODIFICATION HISTORY
-- Person      Date     Comments
-- ---------   ------   -----------------------------------------------------------
-- ***         **2016   TDR 2.0
-- nnt         20170420 CRAPP-3518, cleanup
-- nnt         20170912 reapplied Add_verification (prototype procedure) CRAPP-3918
-- pmr         20171026 CRAPP-2800 Added bulk verification process for taxability review process.

  E_Mandatory EXCEPTION;

    -- Query Form Section
    listTaxability   varchar2(64):=' '; -- list of values 'n,n,...n'
    listTaxSystem    varchar2(64):=' '; -- list of values 'n,n,...n'
    listSpecApplic   varchar2(64):=' '; -- list of values 'n,n,...n'
    listTransApplic  varchar2(64):=' '; -- list of values 'n,n,...n'
    listCalcMethod   varchar2(64):=' '; -- list of values 'n,n,...n'

    gLoop   NUMBER      := 0;
    sq_Main CLOB        := ' ';              -- For building Main query
    sq_Current_Rev CLOB := ' ';              -- For building current revision query
    sq_Include_Tag CLOB := ' ';              -- For building tag request

    -- Form Types --
    TYPE XMLFormTaxability_Taxable_TT IS TABLE OF XMLFormTaxability_Taxable;

type appl_header is record
(
id NUMBER,
nkid number,
applicability_type_id NUMBER,   -- New
calculation_method NUMBER,
input_recoverability NUMBER,
basis_percent NUMBER,
recoverable_amount number,
charge_type_id NUMBER,         -- New
Unit_of_Measure  NUMBER,             --NEW
ref_Rule_Order   NUMBER,         -- New
Tax_Type    varchar2(5),            -- New
start_date DATE,
end_date DATE,
all_taxes_apply number,
commodity_id    number,
jurisdiction_id number,
entered_by number,
default_Taxability   VARCHAR2(1),   -- NEW
product_Tree_Id     NUMBER,
entered_Date        Date,  -- New
is_local            number,
legal_statement    varchar2(5000),
ls_start_date date,
deleted  number
);

type appl_header_ty is table of appl_header;

type xmlform_appltaxes is record
(
  id number
, juris_tax_imposition_id number
, juris_tax_applicability_id number
, ref_rule_order number
, tax_type varchar2(20 char)
, taxtypeid number
, start_date date
, end_date date
, deleted varchar2(1)
, invoice_statement varchar2(200 char)
);


TYPE xmlform_appltaxes_ty IS TABLE OF xmlform_appltaxes;

type xmlform_applcond is record
(
ID                              NUMBER,
--NKID                            NUMBER,
--JURIS_TAX_APPLICABILITY_NKID      NUMBER,
JURIS_TAX_APPLICABILITY_ID        NUMBER,
--JURISDICTION_NKID                 NUMBER,
JURISDICTION_ID                   NUMBER,
REFERENCE_GROUP_ID                NUMBER,
TAXABILITY_ELEMENT_ID           NUMBER,
LOGICAL_QUALIFIER               VARCHAR2(100),
VALUE                           VARCHAR2(100),
ELEMENT_QUAL_GROUP              VARCHAR2(100),
START_DATE                      DATE,
END_DATE                        DATE,
--ENTERED_BY                      NUMBER,
--ENTERED_DATE                    TIMESTAMP(6),
--STATUS                          NUMBER,
QUALIFIER_TYPE                  VARCHAR2(16),
deleted                         VARCHAR2(1 CHAR)

);

TYPE xmlform_applcond_ty IS TABLE OF xmlform_applcond;

type xmlform_applattr is record
(
ID                              NUMBER,
--NKID                            NUMBER,
JURIS_TAX_APPLICABILITY_ID     NUMBER,
--JURIS_TAX_APPLICABILITY_NKID   NUMBER,
ATTRIBUTE_ID                   NUMBER,
START_DATE                     DATE,
END_DATE                       DATE,
--ENTERED_BY                     NUMBER,
--ENTERED_DATE                    DATE,
VALUE                          CLOB,
DELETED                         VARCHAR2(1)
);

TYPE xmlform_applattr_ty IS TABLE OF xmlform_applattr;


    TYPE outSet IS record
    (
     jurisdiction_id NUMBER,
     jurisdiction_nkid NUMBER,
     jurisdiction_rid NUMBER,
     juris_tax_applic_refcode VARCHAR2(4000 CHAR),
     applicability_type_name VARCHAR2(250 CHAR),
     juris_tax_imp_reflist VARCHAR2(4000 CHAR), -- playing with this one 10/27
     juris_tax_applic_ids VARCHAR2(4000 CHAR),
     juris_tax_applic_entity_rid number,
     juris_tax_applic_start varchar2(10 CHAR),
     juris_tax_applic_end varchar2(10 CHAR),
     commodity_tax_group_name VARCHAR2(250 CHAR),
     commodity_tax_group_rid number,
     all_taxes_apply number
    );
    TYPE outTable IS TABLE OF outSet;

    /* Link test record */
    TYPE rDisplayLink IS RECORD
    ( linkId NUMBER
    , linkArrIx NUMBER
    , linkArrValue number);

    -- Additional attributes dataset
    TYPE dsAdditional IS record
    (transtaxid number
    ,juristaxappid number
    ,applicability_type_id number
    ,attrValue varchar2(64)
    ,catid number
    ,catname varchar2(64)
    ,attribute_id number
    ,attributeName varchar2(64)
    ,lookupvalue varchar2(64)
    ,start_date date
    ,end_date DATE
    );
    TYPE tblAdditional IS TABLE OF dsAdditional;

    -- Description dataset
    TYPE outDSRec IS RECORD
    (description varchar2(64),
     id number
     );
    TYPE outDSTbl IS TABLE OF outDSRec;

    -- Taxability Edit Form Header Datatable and Dataset
    TYPE outTaxabHDR_DS IS RECORD
    (jurisdiction_id NUMBER,
     start_date varchar2(10),
     end_date varchar2(10),
     tax_categorization VARCHAR2(128),
     tax_reference_code varchar2(16),
     tax_impos_ref_code varchar2(16),
     basis_percent NUMBER,
     calculation_method varchar2(32),
     juris_tax_imposition_id NUMBER,
     tax_applicability_id NUMBER,
     tax_description_id NUMBER,
     calculation_method_id NUMBER,
     attribute_value varchar2(32),
     attribute_id NUMBER,
     description_id NUMBER,
     taxation_type_id NUMBER,
     transaction_type_id NUMBER,
     spec_applicability_type_id NUMBER
     );
    TYPE tblTaxabilityHDR IS TABLE OF outTaxabHDR_DS;

    -- Taxability header section
    TYPE outHeaderDS IS RECORD
    (rid NUMBER,
     nkid NUMBER,
     id NUMBER,
     entity_rid NUMBER,
     rev_next_rid NUMBER,
     tax_applicability_sets_id varchar2(4000),
     tax_reference varchar2(256),
     reference_code varchar2(16),
     calculation_method_id NUMBER,
     recoverable_percent NUMBER,
     basis_percent NUMBER,
     start_date varchar2(10),
     end_date varchar2(10),
     status number,
     all_taxes_apply number,
     citationsjx CLOB
     );
    TYPE outHeaderTable IS TABLE OF outHeaderDS;

    -- Taxable/Exempt Group
    TYPE outGroupDS IS RECORD
    (id NUMBER,
     rid NUMBER,
     nkid NUMBER,
     juris_tax_applicability_id NUMBER,
     commodity_tax_group_id NUMBER,
     commodity_tax_group_rid NUMBER,
     transaction_taxability_id NUMBER,
     taxability_output_id NUMBER,
     applicability_type_id NUMBER,
     applicability_type_name varchar2(32),
     start_date varchar2(10),
     end_date varchar2(10),
     commodity_tax_group_name varchar2(256),
     short_text varchar2(256),
     full_text varchar2(524),
     status number
    );
    TYPE outGroupTable IS TABLE OF outGroupDS;

    TYPE outApplTaxesDS IS RECORD
    (tax_applicability_id_list varchar2(4000),
     juris_tax_imposition_nkid NUMBER,
     juris_tax_imposition_id NUMBER,
     reference_code varchar2(64),
     start_date varchar2(10),
     end_date varchar2(10),
     status NUMBER,
     shorttext varchar2(100)
    );
    TYPE outApplTaxes IS TABLE OF outApplTaxesDS;

    TYPE outLookupDS IS RECORD
    (id number,
     rid number,
     nkid number,
     reference_code varchar2(64),
     start_date varchar2(10),
     end_date varchar2(10),
     taxation_type varchar2(64),
     transaction_type varchar2(64),
     specific_applicability_type varchar2(64)
    );
    TYPE outLkpRefCode IS TABLE OF outLookupDS;

    TYPE outLkpTxDS IS RECORD
    (jtd_id NUMBER,
    jurisdiction_id NUMBER,
    jtd_name varchar2(250),
    jtd_description varchar2(1000),
    jtd_start_date varchar2(10),
    jtd_end_date varchar2(10),
    jtd_rid NUMBER,
    jtd_nkid number);
    TYPE outLkpTxDescr IS TABLE OF outLkpTxDS;

    -- Additional attributes
    TYPE outAdditionalDS IS record
    (  attribute_id number
      ,attribute_category_id number
      ,value varchar2(64)
      ,start_date varchar2(10)
      ,end_date varchar2(10)
      ,status NUMBER
      ,id NUMBER
      ,rid NUMBER
      ,nkid number
      ,attrname varchar2(100)
    );
    TYPE outAddAttrib IS TABLE OF outAdditionalDS;

    -- Conditions
    TYPE outConditionsDS IS record
    (
      id                        number,
      nkid                      number,
      rid                       number,
      next_rid                  number,
      entity_rid                number,
      entity_nkid               number,
      entity_next_rid           number,
      juris_tax_applicability_id number,
      taxability_element_id     number,
      logical_qualifier         varchar2(64),
      qualifier_value           varchar2(64),
      jurisdiction_id           number,
      start_date                varchar2(12),
      end_date                  varchar2(12),
      status                    number,
      status_modified_date      varchar2(12),
      entered_by                number,
      entered_date              varchar2(12),
      is_current                number
     );
    TYPE outConditions IS TABLE OF outConditionsDS;

	-- Below Record and Type added as part of CRAPP-3509
	TYPE xmlform_taxabilitygroup is record
	(
	id 			NUMBER,
	nkid 		NUMBER,
	end_date 	DATE
	);

	TYPE xmlform_taxabilitygroup_ty IS TABLE OF xmlform_taxabilitygroup;

    -- build IN list when search parameter contains more than one value
    FUNCTION fnAndIs(searchVar IN VARCHAR2, dataCol IN varchar2) RETURN VARCHAR2;

    /** Taxability Search Main Function
     *
     *  pjurisdiction_id - required jurisdiction_id
     *  pTaxabilityRefCode - juris_tax_applicabilities reference_code
     *  pTaxability - applicability_type_id
     *  pTaxSystem - taxation_type_id
     *  pSpecApplic - spec_applicability_type_id
     *  pTransApplic - transaction_type_id
     *  pCalcMethod - calc_method_id
     *  pTags - <n/a ToDo>
     *  pEffective - required juris_tax_applicabilities start_date
     *  pRevision -
     */
    FUNCTION searchTaxability
    (        pjurisdiction_id IN number,
             pTaxabilityRefCode IN VARCHAR2 DEFAULT null,
             pTaxability IN VARCHAR2 DEFAULT null,
             pTaxSystem IN VARCHAR2 DEFAULT null,
             pSpecApplic IN VARCHAR2 DEFAULT null,
             pTransApplic IN VARCHAR2 DEFAULT null,
             pCalcMethod IN VARCHAR2 DEFAULT NULL,
             pTags IN VARCHAR2 DEFAULT NULL,
             pEffective IN VARCHAR2 DEFAULT NULL,
             pRevision IN VARCHAR2 DEFAULT NULL
    )
    RETURN outTable PIPELINED;

    FUNCTION fnDisplayHeader (applicability_rid IN number)
    RETURN outHeaderTable PIPELINED;

    FUNCTION fnDisplayGroups (applicability_rid IN number)
    RETURN outGroupTable PIPELINED;

    FUNCTION fnDisplayTaxes(applicability_rid IN number)
    RETURN outApplTaxes PIPELINED;

    FUNCTION fnLookupRefCode(jurisdiction_nkid IN NUMBER)
    RETURN outLkpRefCode PIPELINED;

    FUNCTION fnDisplayAdditional(applicability_rid IN NUMBER)
    RETURN outAddAttrib PIPELINED;

    function fnDisplayConditions(applicability_rid IN NUMBER)
    return outConditions PIPELINED;

    -- Dataset Tags
    FUNCTION returnUniqueTags RETURN outDSTbl PIPELINED;

    -- Dataset Calculation Methods
    FUNCTION returnCalculationMethod RETURN outDSTbl PIPELINED;

    -- Return list of unique Calculation_Structure_Id
    FUNCTION retCalculation_Structure_Id RETURN VARCHAR2;

    -- Return list of taxability types
    FUNCTION retTaxabilityType_Id RETURN VARCHAR2;

     -- Return Additional section
    FUNCTION fAdditional(juristaxid IN NUMBER DEFAULT NULL
                        ,applicType IN NUMBER DEFAULT 1)
                        RETURN tblAdditional PIPELINED;

    -- Development: taxability pl/table
    FUNCTION taxab_section_lookup(sectionName IN VARCHAR2)
    RETURN outDSTbl PIPELINED;

    -- DS lookup header information - pipe record back
    FUNCTION taxab_header_lookup(jurisdiction_id IN number,
                                 code IN VARCHAR2,
                                 taxation_type_id IN NUMBER,
                                 transaction_type_id IN NUMBER,
                                 spec_applicability_type_id IN NUMBER,
                                 tax_description_id IN NUMBER,
                                 calculation_method_id IN NUMBER)
                                 RETURN tblTaxabilityHDR PIPELINED;

    PROCEDURE lookup_cmbx(cmbx_name IN VARCHAR2
                         ,p_ref OUT SYS_REFCURSOR);

    PROCEDURE uiApplicability_Types(fStatus IN NUMBER
                                 ,p_ref OUT SYS_REFCURSOR);
    PROCEDURE uiTax_Descriptions(fStatus IN NUMBER, fTr_type IN NUMBER
                              ,fTx_type IN NUMBER, fSp_type IN NUMBER
                              ,p_ref OUT SYS_REFCURSOR);
    PROCEDURE uiCalculation_Methods(fStatus IN NUMBER, p_ref OUT SYS_REFCURSOR);

    PROCEDURE slProduct_List(jurisdiction_id IN NUMBER
                         ,tax_description_id IN NUMBER
                         ,ref_code IN VARCHAR2
                         ,calc_method_id IN NUMBER
                         ,dStartDate IN DATE DEFAULT NULL
                         ,dEndDate IN DATE DEFAULT null);

    -- Lookup - Tags
    PROCEDURE lkpGetTags(refCurs OUT SYS_REFCURSOR);
    -- Lookup - Calculation Methods
    PROCEDURE lkpCalculationMethod(refCurs OUT SYS_REFCURSOR);

    PROCEDURE vSelectFormHeader(jurisdiction_id IN number,
                                code IN VARCHAR2,
                                taxation_type_id IN NUMBER,
                                transaction_type_id IN NUMBER,
                                spec_applicability_type_id IN NUMBER,
                                tax_description_id IN NUMBER,
                                calculation_method_id IN NUMBER,
                                p_ref OUT SYS_REFCURSOR);

    /** XML - Taxability Update Form
     *
     **/
    PROCEDURE XMLProcess_Form(sx IN CLOB, success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER, copy_flag IN NUMBER DEFAULT 0);


    PROCEDURE genCreateTransactionTaxId(nApplicability_id IN NUMBER,
                                     pnTransaction_Tax_Id IN OUT NUMBER,
                                     nApplicability_Type_id IN NUMBER,
                                     sTrans_Name IN VARCHAR2,
                                     dStart_Date IN DATE,
                                     dEnd_Date IN DATE,
                                     nEntered_by IN NUMBER,
                                     p_rid_o OUT number,
                                     p_nkid_o OUT number);

    /* Update/Insert Form Data */
    PROCEDURE form_update_full(frmHeader IN appl_header,
                           rec_appl_attr IN xmlform_applattr_ty,
                           rec_appl_taxes   IN     xmlform_appltaxes_ty,
                           rec_appl_cond IN xmlform_applcond_ty,
                           tag_list IN xmlform_tags_tt,
                           rid_o OUT NUMBER,
                           nkid_o OUT NUMBER);

    PROCEDURE update_header(header_rec IN appl_header, jtaId IN OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER);

    PROCEDURE update_taxes(rec_i xmlform_appltaxes, appltax_pk out number, entered_by_i number, jta_id number default null, applicability_type_i number,
							default_taxability_i number, is_local_i number
							);

    PROCEDURE update_attributes( rec_i IN xmlform_applattr, applattr_pk OUT NUMBER, entered_by_i number, jta_id number default null);

    procedure update_condition( rec_i xmlform_applcond, applcond_pk OUT NUMBER , entered_by_i number, jta_id number default null  );

    PROCEDURE remove_taxes(appltax_id IN VARCHAR2, deleted_by_i IN number, jta_nkid number,  Applicability_Type_ID number);
    PROCEDURE remove_attribute(jta_att_id IN NUMBER, deleted_by_i IN number);
    PROCEDURE remove_condition (condition_id IN NUMBER, deleted_by_i IN NUMBER);

    PROCEDURE Remove_Taxability_Items(refSection IN number,
          tax_app_set IN XMLFormTaxability_TaxApplSets,
          deleted_by_i IN number);

    PROCEDURE getTaxability( pjurisdiction_id IN number,
                             pTaxabilityRefCode IN VARCHAR2 DEFAULT NULL,
                             pTaxability IN VARCHAR2 DEFAULT NULL,
                             pTaxSystem IN VARCHAR2 DEFAULT NULL,
                             pSpecApplic IN VARCHAR2 DEFAULT NULL,
                             pTransApplic IN VARCHAR2 DEFAULT NULL,
                             pCalcMethod IN VARCHAR2 DEFAULT NULL,
                             pTags IN VARCHAR2 DEFAULT NULL,
                             pEffective IN VARCHAR2 DEFAULT NULL,
                             pRevision IN VARCHAR2 DEFAULT NULL,
                             p_ref OUT SYS_REFCURSOR);

    PROCEDURE taxability_header(applicability_rid IN NUMBER,
                                p_ref OUT sys_refcursor);

    PROCEDURE taxability_groups(applicability_rid IN NUMBER,
                                p_ref OUT sys_refcursor);
    -- could add overload proc to cover other in parameters if needed
    PROCEDURE taxability_applic(applicability_rid IN NUMBER,
                                p_ref OUT sys_refcursor);

    -- Lookup imposition reference codes for applicable taxes
    PROCEDURE lookup_imp_refcode(jurisdiction_nkid IN NUMBER,
                               p_ref OUT sys_refcursor);

    PROCEDURE taxability_additional(applicability_rid IN NUMBER,
                                p_ref OUT sys_refcursor);

    PROCEDURE taxability_conditions(applicability_rid   IN  NUMBER,
                                p_ref OUT SYS_REFCURSOR);

    -- Delete Revision
    PROCEDURE delete_revision(  jta_id IN NUMBER,
                                deleted_by_i IN NUMBER,
                                success_o OUT NUMBER,
                                prev_rid  OUT NUMBER,
                                nkid_o   OUT NUMBER);
    PROCEDURE delete_revision
       (
       resetAll IN Number,
       revision_id_i IN NUMBER,
       deleted_by_i IN NUMBER,
       success_o OUT NUMBER
       ); -- Overloaded 1

    -- Jurisdiction COPY event
    -- Note: This is the Alpha version...
    -- Additional parameters might be needed to cover specific scenarios
    PROCEDURE Copy_Taxability(pJuris_taxab_id IN NUMBER
                              ,pNewJurisdiction IN number
                              ,pEntered_by IN NUMBER
                              ,rtnCopied OUT NUMBER);

    PROCEDURE unique_check(juris_nkid_i IN NUMBER, ref_code_i IN VARCHAR2, nkid_i IN NUMBER);

    PROCEDURE reset_status
       (
       revision_id_i IN NUMBER,
       reset_by_i IN NUMBER,
       success_o OUT NUMBER
       );

--procedure insert_appltaxes ( sx clob );
procedure update_appltaxes ( sx clob, success out number, appltax_pk out number );
procedure update_applconditions ( sx clob, success out number, applcond_pk out number );
procedure update_applattribute ( sx clob, success out number, applattr_pk out number );

Procedure Update_ApplHeader (sx clob, success out number, appl_pk out number );

/*PROCEDURE generate_xml_old (jta_id_i        NUMBER,
                        juris_id        NUMBER,
                        entered_by_i    NUMBER,
                        start_date_i      date,
                        end_date_i        date default null
                        );
*/
PROCEDURE generate_xml (jta_id_i        NUMBER,
                        juris_nkid      NUMBER,
                        entered_by_i    NUMBER,
                        start_date_i    date,
                        end_date_i      date default null,
                        local_flag      number default 0,
                        commodity_list  varchar2_32_t default null);

procedure enddate_taxability( jta_id_i number, start_date_i date);

procedure update_applattribute_dev ( sx clob, success out number, applattr_pk out number );

PROCEDURE processCopy_Locally( jta_list_i in clob, Start_Date_i in date, entered_by_i number, processid_io out number, success_o out number);
PROCEDURE processCopy_Locally1( selectedJTA in clob, defStartDate in date,  entered_by number);

-- Start changes for CRAPP-2800

PROCEDURE add_bulk_verification (revisionids    IN     CLOB,
                            enteredby      IN     NUMBER,
                            reviewtypeid   IN     NUMBER,
                            success_o         OUT NUMBER);

PROCEDURE remove_bulk_verification (revisionids    IN     CLOB,
                            enteredby      IN     NUMBER,
                            success_o         OUT NUMBER);
-- End changes for CRAPP-2800

-- CRAPP-3918 (includes CRAPP-3921)
procedure add_verification(
    revisionId IN NUMBER,
    enteredBy IN NUMBER,
    reviewTypeId in number,
    success_o OUT NUMBER);

-- CRAPP-3509
PROCEDURE update_taxability(
				sx        IN  CLOB,
				success_o OUT NUMBER);


-- Start changes for CRAPP-2800

PROCEDURE add_bulk_verification (revisionids    IN     CLOB,
                            enteredby      IN     NUMBER,
                            reviewtypeid   IN     NUMBER,
                            success_o         OUT NUMBER);

PROCEDURE remove_bulk_verification (revisionids    IN     CLOB,
                            enteredby      IN     NUMBER,
                            success_o         OUT NUMBER);
-- End changes for CRAPP-2800

END TAXABILITY;
/