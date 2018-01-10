CREATE OR REPLACE PACKAGE sbxtax.det_update
  IS
    PROCEDURE compare_authority_logic(make_changes_i IN NUMBER);
    PROCEDURE compare_authority_message(make_changes_i IN NUMBER);
    PROCEDURE compare_authorities(make_changes_i IN NUMBER);
    PROCEDURE compare_contributing_auths(make_changes_i IN NUMBER);
    PROCEDURE compare_rates(make_changes_i IN NUMBER);
    PROCEDURE compare_rules(make_changes_i IN NUMBER);
    PROCEDURE compare_products(prod_group_id_i IN NUMBER, make_changes_i IN NUMBER);
    PROCEDURE compare_reference_lists(make_changes_i IN NUMBER);
    PROCEDURE compare_reference_values(make_changes_i IN NUMBER);
    PROCEDURE log_failure(ex_i IN VARCHAR2, table_name_i IN VARCHAR2, pk_i IN NUMBER, cause_i IN VARCHAR2);
    function merchant_id(name_i IN VARCHAR2) RETURN NUMBER;
    function parent_product_category_id(commodity_nkid_i IN NUMBER) RETURN NUMBER;
    function parent_commodity_nkid(commodity_nkid_i IN NUMBER) RETURN NUMBER;
    PROCEDURE remove_authority(authority_i IN VARCHAR2);
    PROCEDURE remove_rates(authority_i IN VARCHAR2);
    PROCEDURE remove_rules(authority_i IN VARCHAR2);
    --PROCEDURE remove_auth_logic(authority_i IN VARCHAR2(100));
    --PROCEDURE remove_cont_auth(authority_i IN VARCHAR2(100));
    PROCEDURE remove_product(comm_code_i IN VARCHAR2);
    --PROCEDURE remove_ref_list(name_i IN VARCHAR2(100));
    --PROCEDURE sync_sequences;

    PROCEDURE truncate_tmp_table(entity_name_i in varchar2);
    PROCEDURE set_loaded_date(entity_name_i varchar2);

END det_update;
/