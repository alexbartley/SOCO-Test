CREATE OR REPLACE PACKAGE content_repo."COMMODITY" 
  IS
-- *****************************************************************
-- Description:
--
-- Revision History
-- Date            Author       Reason for Change
-- ----------------------------------------------------------------
-- 5/18/2016                    DEV2 Comm groups removed
--
-- *****************************************************************

    TYPE XMLForm_CommAttr_Rec IS RECORD
    (
        uiuserid NUMBER,
        recid   NUMBER,
        recrid   NUMBER,
        recnkid   NUMBER,
        attribute_id NUMBER,
        value VARCHAR2 (128),
        start_date date,
        end_date date,
        modified NUMBER ,
        deleted NUMBER,
        comm_id NUMBER
    );

    TYPE XMLForm_CommAttr_TT IS TABLE OF XMLForm_CommAttr_Rec;

    PROCEDURE XMLProcess_Form_Comm(
    sx IN CLOB,
    update_success OUT NUMBER,
    nkid_o OUT NUMBER,
    rid_o OUT NUMBER);

    PROCEDURE update_full (
    details_i IN XMLFormCommodity,
   -- att_list_i IN XMLForm_CommAttr_TT,
    tag_list IN xmlform_tags_tt,
    rid_o OUT NUMBER,
    nkid_o OUT NUMBER
    );

    PROCEDURE
    update_record (
    id_io IN OUT NUMBER,
    details_i IN XMLFormCommodity,
    nkid_o OUT NUMBER,
    rid_o OUT NUMBER
    );

    PROCEDURE delete_revision
       (
       revision_id_i IN NUMBER,
       deleted_by_i IN NUMBER,
       success_o OUT NUMBER,
       existsInGroups OUT CLOB
    );

    -- Overloaded: delete_revision, reset, remove attachments

    PROCEDURE delete_revision
       (
       resetAll IN Number,
       revision_id_i IN NUMBER,
       deleted_by_i IN NUMBER,
       success_o OUT NUMBER,
       existsInGroups OUT CLOB
       );


    PROCEDURE remove_commodity (
    id_i IN NUMBER,
    deleted_by_i IN NUMBER
    );

    FUNCTION get_revision (
        rid_i IN NUMBER,
        entered_by_i IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_revision (
        entity_id_io IN OUT NUMBER,
        entity_nkid_i IN NUMBER,
        entered_by_i IN NUMBER
    ) RETURN NUMBER;

    PROCEDURE remove_attribute (
      id_i IN NUMBER,
      deleted_by_i IN NUMBEr
    );

    PROCEDURE update_attribute (
        id_io IN OUT NUMBER,
        comm_id_i IN NUMBER,
        attribute_id_i IN NUMBER,
        value_i IN VARCHAR2,
        start_date_i IN DATE,
        end_date_i IN DATE,
        entered_by_i IN NUMBER
    );

    FUNCTION get_current_revision (p_nkid IN NUMBER) RETURN NUMBER;
    PROCEDURE unique_check(name_i IN VARCHAR2, prod_tree_i IN NUMBER, h_code_i VARCHAR2,nkid_i IN NUMBER);
  --  Procedure add_associated_groups(sx in CLOB, success_o OUT number, log_id_o OUT number);
    PROCEDURE reset_status
       (
       revision_id_i IN NUMBER,
       reset_by_i IN NUMBER,
       success_o OUT NUMBER
       );

END COMMODITY;
/