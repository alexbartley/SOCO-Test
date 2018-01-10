CREATE OR REPLACE PACKAGE content_repo.change_mgmt
IS
--
-- Purpose: Handle operations related to managing Content record changes
--
-- MODIFICATION HISTORY
-- Person           Date         Comments
-- u0126589/genesam 09-Apr-2013
-- tnn              10-FEB-2014  changed type XMLFORM_CITATION text #
-- tnn              24-FEB-2014  Dependencies type tables
-- tnn              02-JUN-2014  juris_tax_app_chg_log_id column was missing
-- tnn              *01-AUG-2014 Bulk verification
--                  *01-SEP-2014 unlock_revision
-- tnn              24-AUG-2016  bulk tags
--                               Dependencies: Package tags_registry
-- tnn              20-OCT-2016  1775 / Bulk op

  -- CRAPP-2929
  type tTags is table of tags%rowtype index by binary_integer;

  TYPE chglogids IS TABLE OF INTEGER;

  -- Get log table list by the entity type
  FUNCTION getLogTables_Chg(iEntityType IN number) RETURN VARCHAR2;
  FUNCTION getLogTables(iEntityType IN number) RETURN VARCHAR2;
  FUNCTION getLogTables(iEntityType IN number, userList in varchar2) RETURN VARCHAR2;

    PROCEDURE sign_admin_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        );

    PROCEDURE sign_juris_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        );

    PROCEDURE sign_juris_type_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        );

    PROCEDURE unsign_juris_chg_logs(
        chg_log_rvws_i IN chglogids
        );

    PROCEDURE unsign_juris_type_chg_logs(
        chg_log_rvws_i IN chglogids
        );

    PROCEDURE unsign_admin_chg_logs(
        chg_log_rvws_i IN chglogids
        );

    PROCEDURE unsign_tax_chg_logs(
        chg_log_rvws_i IN chglogids
        );

    PROCEDURE unsign_tax_app_chg_logs(
        chg_log_rvws_i IN chglogids
        );

    PROCEDURE unsign_comm_chg_logs(
        chg_log_rvws_i IN chglogids
        );

    /*
    PROCEDURE unsign_comm_grp_chg_logs(
        chg_log_rvws_i IN chglogids
        );
    */

    PROCEDURE unsign_ref_grp_chg_logs(
        chg_log_rvws_i IN chglogids
        );

    PROCEDURE sign_tax_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        );

    PROCEDURE sign_tax_app_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        );

    PROCEDURE sign_comm_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        );

    /*
    PROCEDURE sign_comm_grp_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        );
    */

    PROCEDURE sign_ref_grp_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        );

    PROCEDURE sign_gis_unique_chg_logs(
        chg_logs_i IN chglogids,
        reviewed_by_i IN NUMBER,
        review_type_id_i IN NUMBER
        );

    PROCEDURE XMLProcess_Form_UpdChgLog(
        sx IN CLOB,
        update_success OUT NUMBER
        );

    PROCEDURE XMLProcess_Form_RvwChgLog(
        sx IN CLOB,
        update_success OUT NUMBER
        );

    PROCEDURE upd_change_logs(
        entity_i IN VARCHAR2,
        change_logs_i IN chglogids,
        citations_i IN XMLForm_Cita_TT,
        external_links_i IN XMLForm_External_Ref_TT,
        change_reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER,
        entered_by_i IN NUMBER
        );


    PROCEDURE add_admin_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        );

    PROCEDURE add_juris_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        );

    -- Jurisdiction Type
    PROCEDURE add_juris_type_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        );

    PROCEDURE add_tax_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        );

    PROCEDURE add_tax_app_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        );

    PROCEDURE add_comm_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        );

    /*
    PROCEDURE add_comm_grp_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        );
    */

    PROCEDURE add_ref_grp_chg_rsn(
        change_log_id_i IN NUMBER,
        reason_id_i IN NUMBER,
        summary_i IN VARCHAR2,
        overwrite_i IN NUMBER DEFAULT 0,
        entered_by_i IN NUMBER
        );

    PROCEDURE add_admin_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        );

     PROCEDURE add_juris_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        );

      PROCEDURE add_tax_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        );

      PROCEDURE add_juris_type_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        );

      PROCEDURE add_tax_app_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        );

    PROCEDURE add_comm_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        );

    /*
    PROCEDURE add_comm_grp_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        );
    */

    PROCEDURE add_ref_grp_chg_cit(
        change_log_id_i IN NUMBER,
        citation_id_i IN NUMBER,
        entered_by_i IN NUMBER
        );

    PROCEDURE unlock_revision(ientity_type IN NUMBER, iRid IN NUMBER, unlock_success OUT NUMBER);
    PROCEDURE unlock_revision(ientity_type IN NUMBER, iRid IN NUMBER, unlock_success OUT NUMBER, userList in varchar2);
    PROCEDURE unlock_change_log(ientity_type IN NUMBER, iChgLog IN NUMBER, unlock_success OUT NUMBER);
    PROCEDURE unlock_change_log(ientity_type IN NUMBER, iChgLog IN NUMBER, unlock_success OUT NUMBER, userList in varchar2);

    -- remove pending revisions
    Procedure remove_pending(pEntity_type in number, rid_list in clob, deleted_by_i in number,
                             success_o out number, logId_o out number);
    -- {public} for test
    PROCEDURE dev_vld_remove(ientity_type IN NUMBER, iRid IN NUMBER, unlock_success OUT NUMBER);

    -- Update change log bulk verification
    procedure Bulk_Verification(pEntity_Type in number
                              , change_id_list in clob
                              , verif_type in number
                              , entered_by in number
                              , success_o out number);

    -- Bulk remove verification
    -- ToDo: add flag to log table +action
    procedure Bulk_Remove_Verification(pEntity_Type in number
                                     , rid_list in clob
                                     , deleted_by_i in number
                                     , success_o out number
                                     , logId_o out number);

    -- OV
    procedure Bulk_Remove_Verification(pEntity_Type in number
                                     , rid_list in clob
                                     , deleted_by_r in varchar2
                                     , success_o out number
                                     , logId_o out number);

    procedure Bulk_Remove_Verif_Chg (pEntity_Type in number
                                     , changelog_list in clob
                                     , deleted_by_i in number
                                     , success_o out number
                                     , logId_o out number
                                     , myVerification in number);

    procedure Bulk_Remove_Verif_Chg (pEntity_Type in number
                                     , changelog_list in clob
                                     , deleted_by_r in varchar2
                                     , success_o out number
                                     , logId_o out number
                                     , myVerification in number);

    procedure Bulk_Unlink_Doc(sx IN CLOB, success OUT NUMBER);

    -- Very basic right now
    -- ToDo: build on; keep track of entity and records that can't be removed
    PROCEDURE log_remove(pId in number, pRid in number, pEntity in number);

    procedure Bulk_Remove_Revision(pEntity_Type in number
                                    , rid_list in clob
                                    , deleted_by_i in number
                                    , success_o out number
                                    , logId_o out number);

    -- CRAPP-2929 Main()
    procedure Bulk_Add_Tags(pEntity_Type in number
    ,change_id_list in clob
    ,tagId_list in varchar2
    ,nRemove in number default 0
    ,editedBy in number
    ,success_o out number
    ,logId_o out number);


    /*
    || Each entity has its own procedure
    || Could have used the concept of using the 'getLogTables'
    || This could be replaced with one procedure
    */
    -- CRAPP-2929
    -- Uses TAGS_REGISTRY package and types
    procedure add_tags_admin(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        );

    -- CRAPP-2929
    -- Uses TAGS_REGISTRY package and types
    procedure add_tags_juris(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        );

    PROCEDURE add_tags_juris_type(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        );

    -- CRAPP-2929
    -- Uses TAGS_REGISTRY package and types
    procedure add_tags_tax(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        );

    -- CRAPP-2929
    -- Uses TAGS_REGISTRY package and types
    procedure add_tags_taxability(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        );

    -- CRAPP-2929
    -- Uses TAGS_REGISTRY package and types
    procedure add_tags_comm(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        );

    procedure add_tags_ref(
        chg_logs_i IN chglogids,
        enteredBy IN NUMBER,
        tagid_list IN varchar2,
        nAddOrRemove in number default 0
        );



END change_mgmt;
/