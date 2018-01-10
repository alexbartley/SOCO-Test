CREATE OR REPLACE PACKAGE content_repo.JURISDICTION_TYPE
  IS
-- *****************************************************************
-- Description: Process Administrator XML, Copy administrator,
--              add and remove items, delete/get revision
--
-- Revision History
-- Date            Author       Reason for Change
--
-- ----------------------------------------------------------------


PROCEDURE XMLProcess_Form_JurisType(sx IN CLOB, update_success OUT NUMBER, nkid_o OUT NUMBER, rid_o OUT NUMBER);

    PROCEDURE update_full (
    details_i IN xmlformjuristype,
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

END ;
/