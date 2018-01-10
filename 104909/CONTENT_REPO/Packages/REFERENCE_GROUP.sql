CREATE OR REPLACE PACKAGE content_repo."REFERENCE_GROUP" 
  IS


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

    PROCEDURE XMLProcess_Form_RefGrp(
    sx IN CLOB,
    update_success OUT NUMBER,
    nkid_o OUT NUMBER,
    rid_o OUT NUMBER);

    PROCEDURE update_full (
    details_i IN XMLFormReferenceGroup,
    item_list_i IN XMLFormReferenceItem_TT,
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



    PROCEDURE add_ref_item (
    id_io IN OUT NUMBER,
    ref_group_id_i IN NUMBER,
    value_i IN VARCHAR2,
    value_type_i IN VARCHAR2,
    ref_nkid_i IN NUMBER,
    start_date_i IN DATE,
    end_date_i IN DATE,
    entered_by_i IN NUMBER
    );

    PROCEDURE remove_ref_item (
    id_i IN NUMBER,
    deleted_by_i IN NUMBEr
    );

    PROCEDURE unique_check(name_i IN VARCHAR2, nkid_i IN NUMBER);
    PROCEDURE reset_status(revision_id_i IN NUMBER, reset_by_i IN NUMBER, success_o OUT NUMBER);

END reference_group;
/