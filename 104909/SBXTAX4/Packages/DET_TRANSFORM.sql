CREATE OR REPLACE PACKAGE sbxtax4.det_transform
  IS
    procedure empty_tmp_sbx;
    FUNCTION auth_admin_level (
        admin_type_i IN VARCHAR2,
        loc_cat_i IN VARCHAR2
        ) RETURN NUMBER;
    PROCEDURE rate_codes;
    PROCEDURE build_tb_authorities(package_i IN VARCHAR2);
    PROCEDURE build_tb_contributing_auths;
    PROCEDURE build_tb_auth_logic;
    procedure build_tb_auth_messages;
    PROCEDURE build_tb_rates;
    --PROCEDURE build_tb_rate_tiers;
    PROCEDURE build_tb_product_categories;
    PROCEDURE build_tb_reference_lists;
    PROCEDURE build_tb_reference_values;
    --PROCEDURE build_rule_products;
    PROCEDURE build_tb_rules;
    --PROCEDURE get_product_exceptions;
    --PROCEDURE build_tb_rule_qualifiers;

    FUNCTION tax_type_level(tax_type_i IN VARCHAR2) RETURN NUMBER;
    FUNCTION zone_level_id(name_i IN VARCHAR2) RETURN NUMBER;
    FUNCTIOn tax_type(auth_uuid_i IN VARCHAR2, content_type_i IN VARCHAR2, rate_code_i IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION auth_type_id(name_i IN VARCHAR2) RETURN NUMBER;
    FUNCTION auth_name(juris_name_i IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE map_commodities_products;
    PROCEDURE map_reference_lists;
    PROCEDURE map_rule_rq;
    PROCEDURE map_jta_rq;
    PROCEDURE map_rates;
    PROCEDURE insert_rule(
        auth_uuid_i IN VARCHAR2,
        parent_rule_i IN NUMBER,
        rate_code_i IN VARCHAR2,
        exempt_i IN VARCHAR2,
        no_tax_i IN VARCHAR2,
        comm_nkid_i IN NUMBER,
        h_level_i IN NUMBER,
        tax_type_i IN VARCHAR2,
        start_date_i IN DATE,
        end_date_i IN DATE,
        basis_percent_i IN NUMBER,
        recoverable_percent_i IN NUMBER,
        inv_desc_i IN VARCHAR2,
        tas_nkid_i IN NUMBER);
    FUNCTION gen_inv_desc(tax_desc_i IN VARCHAR2, exempt_i IN VARCHAR2, no_tax_i IN VARCHAR2) RETURN VARCHAR2;
    PROCEDURE set_transformed_date(entity_name_i varchar2);
/*
    -- GIS D2C Procedures -- CRAPP-1859
    PROCEDURE build_tb_comp_areas;
    PROCEDURE build_tb_comp_area_auths(make_changes_i IN NUMBER);  -- 01/26/16 crapp-2244 added parameter
*/
END;
/