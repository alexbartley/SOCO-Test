CREATE OR REPLACE PACKAGE content_repo."ADMINISTRATOR" 
  IS
-- *****************************************************************
-- Description: Process Administrator XML, Copy administrator,
--              add and remove items, delete/get revision
--
-- Revision History
-- Date            Author       Reason for Change
-- ----------------------------------------------------------------


PROCEDURE XMLProcess_Form_Admin1(sx IN CLOB, update_success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER);

    PROCEDURE update_full (
    details_i IN XMLFormAdministrator,
    att_list_i IN XMLForm_Admin_Attr_TT,
    atr_list_i IN XMLForm_Admin_Tax_Reg_TT,
    tag_list IN xmlform_tags_tt,
    rid_o OUT NUMBER,
    nkid_o OUT NUMBER
    );

    PROCEDURE update_record (
    id_io IN OUT NUMBER,
    name_i IN VARCHAR2,
    description_i IN VARCHAR2,
    start_date_i IN DATE,
    end_date_i IN DATE,
    requires_registration_i IN NUMBER,
    collects_tax_i IN NUMBER,
    notes_i IN VARCHAR2,
    admin_type_id_i IN NUMBER,
    entered_by_i IN NUMBER,
    nkid_o OUT NUMBER,
    rid_o OUT NUMBER
    );

    PROCEDURE copy (
    rid_io IN OUT NUMBER,
    nkid_io OUT NUMBER,
    new_name_i IN VARCHAR2,
    copy_reg_i IN NUMBER,
    copy_details_i IN NUMBER,
    copy_contacts in NUMBER,
    entered_by_i IN NUMBER
    );

    PROCEDURE delete_revision (
    revision_id_i IN NUMBER,
    deleted_by_i IN NUMBER,
    success_o OUT NUMBER
    );

    -- Overloaded 1
    PROCEDURE delete_revision (
       resetAll IN Number,
       revision_id_i IN NUMBER,
       deleted_by_i IN NUMBER,
       success_o OUT NUMBER
    );

    PROCEDURE update_tax_registration (
    id_io IN OUT NUMBER,
    administrator_id_i IN NUMBER,
    registration_mask_i IN VARCHAR2,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER
    );

    PROCEDURE remove_tax_registration (
    id_i IN NUMBER,
    deleted_by_i IN NUMBEr
    );

    PROCEDURE update_attribute (
    id_io IN OUT NUMBER,
    administrator_id_i IN NUMBER,
    attribute_id_i IN NUMBER,
    value_i IN VARCHAR2,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER
    );

    PROCEDURE remove_attribute (
    id_i IN NUMBER,
    deleted_by_i IN NUMBEr
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

    FUNCTION get_current_revision (p_nkid IN NUMBER) RETURN NUMBER;

    PROCEDURE unique_check(name_i IN VARCHAR2, nkid_i IN NUMBER);
    PROCEDURE reset_status(revision_id_i IN NUMBER, reset_by_i IN NUMBER, success_o OUT NUMBER);

END administrator;
/