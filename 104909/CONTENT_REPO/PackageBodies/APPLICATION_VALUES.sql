CREATE OR REPLACE PACKAGE BODY content_repo."APPLICATION_VALUES"
IS
    PROCEDURE user_tag(id_io IN OUT NUMBER, name_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
        l_tag_type_id NUMBER;
    BEGIN
        SELECT tt.id
        INTO l_tag_type_id
        FROM tag_types tt
        where tt.name like 'USER%';
        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM tags t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update tags
                set name = name_i, tag_type_id = l_tag_type_id, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO tags (tag_type_id, name, entered_by) VALUES ( l_tag_type_id, name_i, entered_by_i) RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END user_tag;
    PROCEDURE attribute_category(id_io IN OUT NUMBER, name_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN
        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM attribute_categories t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update attribute_categories
                set name = name_i,  entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO attribute_categories (name, entered_by) VALUES ( name_i, entered_by_i) RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END attribute_category;
    PROCEDURE taxation_type(id_io IN OUT NUMBER, name_i IN VARCHAR2, description_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN
        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM taxation_types t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update taxation_types
                set name = name_i, description= description_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO taxation_types (name, description, entered_by) VALUES ( name_i, description_i, entered_by_i) RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END taxation_type;
    PROCEDURE transaction_type(id_io IN OUT  NUMBER, name_i IN VARCHAR2, description_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN
        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM transaction_types t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update transaction_types
                set name = name_i, description= description_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO transaction_types (name, description, entered_by) VALUES ( name_i, description_i, entered_by_i) RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END transaction_type;
    PROCEDURE specific_app_type(id_io IN OUT NUMBER, name_i IN VARCHAR2, description_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN
        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM specific_applicability_types t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update specific_applicability_types
                set name = name_i, description= description_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO specific_applicability_types (name, description, entered_by) VALUES ( name_i, description_i, entered_by_i)  RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END specific_app_type;
    PROCEDURE revenue_purpose(id_io IN OUT NUMBER, name_i IN VARCHAR2, description_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN
        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM revenue_purposes t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update revenue_purposes
                set name = name_i, description= description_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO revenue_purposes (name, description, entered_by) VALUES ( name_i, description_i, entered_by_i)  RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END revenue_purpose;
    PROCEDURE product_Tree(id_io IN OUT NUMBER, name_i IN VARCHAR2, short_name_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN
        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM product_Trees t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update product_Trees
                set name = name_i, short_name= short_name_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO product_Trees (name, short_name, entered_by) VALUES ( name_i, short_name_i, entered_by_i) RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END product_Tree;
    PROCEDURE additional_attribute(id_io IN OUT NUMBER, name_i IN VARCHAR2, purpose_i IN VARCHAR2, att_cat_id_i IN NUMBER, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM additional_attributes t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update additional_attributes
                set name = name_i, purpose = purpose_i, attribute_category_id = att_cat_id_i,entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO additional_attributes (name, purpose, attribute_category_id, entered_by) VALUES ( name_i, purpose_i, att_cat_id_i, entered_by_i)  RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END additional_attribute;
    PROCEDURE attribute_lookup(id_io IN OUT NUMBER, value_i IN VARCHAR2, att_id_i IN NUMBER, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM attribute_lookups t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update attribute_lookups
                set value = value_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO attribute_lookups (value, attribute_id, entered_by) VALUES ( value_i, att_id_i, entered_by_i)  RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END attribute_lookup;
    PROCEDURE currency(id_io IN OUT NUMBER, code_i IN VARCHAR2, description_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM currencies t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update currencies
                set currency_code = code_i, description = description_i,entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO currencies (currency_code, description, entered_by) VALUES ( code_i, description_i, entered_by_i) RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END currency;
    PROCEDURE language(id_io IN OUT NUMBER, name_i IN VARCHAR2,  entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM languages t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update languages
                set name = name_i,entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO languages (name,entered_by) VALUES ( name_i, entered_by_i) RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END language;
    PROCEDURE source_type(id_io IN OUT NUMBER, name_i IN VARCHAR2,  entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM source_types t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update source_types
                set name = name_i,entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO source_types (name,entered_by) VALUES ( name_i, entered_by_i) RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END source_type;
    PROCEDURE contact_type(id_io IN OUT NUMBER, name_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM contact_types t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update contact_types
                set name = name_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO contact_types (name, entered_by) VALUES ( name_i, entered_by_i)  RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END contact_type;
    PROCEDURE contact_usage_type(id_io IN OUT NUMBER, name_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM contact_usage_types t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update contact_usage_types
                set name = name_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO contact_usage_types (name, entered_by) VALUES ( name_i, entered_by_i)  RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END contact_usage_type;

    PROCEDURE change_reason(id_io IN OUT NUMBER, name_i IN VARCHAR2,  entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM change_reasons t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update change_reasons
                set reason = name_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO change_reasons (reason, entered_by) VALUES ( name_i, entered_by_i)  RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END change_reason;
    PROCEDURE Assignment_Type(id_io IN OUT NUMBER, name_i IN VARCHAR2, ui_order_i IN NUMBER, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM Assignment_Types t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update Assignment_Types
                set name = name_i, ui_order = ui_order_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO Assignment_Types (name, ui_order, entered_by) VALUES ( name_i, ui_order_i, entered_by_i)  RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END Assignment_Type;
    PROCEDURE geo_area_category(id_io IN OUT NUMBER, name_i IN VARCHAR2, ui_order_i IN NUMBER, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM geo_area_categories t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update geo_area_categories
                set name = name_i, ui_order = ui_order_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO geo_area_categories (name, ui_order, entered_by) VALUES ( name_i, ui_order_i, entered_by_i)  RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END geo_area_category;
    PROCEDURE Calculation_method(id_io IN OUT NUMBER, name_i IN VARCHAR2, description_i IN VARCHAR2, ui_order_i IN NUMBER, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM Calculation_methods t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update Calculation_methods
                set name = name_i, description= description_i,ui_order = ui_order_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO Calculation_methods (name, description, ui_order, entered_by) VALUES ( name_i, description_i, ui_order_i, entered_by_i)  RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END Calculation_method;
    PROCEDURE taxability_element(id_io IN OUT NUMBER, element_name_i IN VARCHAR2, description_i IN VARCHAR2, value_type_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM taxability_elements t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update taxability_elements
                set element_name = element_name_i, description= description_i,element_value_type = value_type_i, entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO taxability_elements (element_name, description, element_value_type, entered_by) VALUES ( element_name_i, description_i, value_type_i, entered_by_i)  RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END taxability_element;
    PROCEDURE del_user_tag(id_i IN NUMBER)
    IS
    BEGIN
        delete from tags
        where id = id_i
        and tag_type_id = (select id from tag_types where name like 'USER%')
        and status = 0;
        commit;
    END del_user_tag;
    PROCEDURE del_attribute_category(id_i IN NUMBER)
    IS
    BEGIN
        delete from attribute_categories
        where id = id_i
        and status = 0;
        commit;
    END del_attribute_category;
    PROCEDURE del_additional_attribute(id_i IN NUMBER)
    IS
    BEGIN
        delete from additional_attributes
        where id = id_i
        and status = 0;
        commit;
    END del_additional_attribute;
    PROCEDURE del_taxation_type(id_i IN NUMBER)
    IS
    BEGIN
        delete from taxation_types
        where id = id_i
        and status = 0;
        commit;
    END del_taxation_type;
    PROCEDURE del_transaction_type(id_i IN NUMBER)
    IS
    BEGIN
        delete from transaction_types
        where id = id_i
        and status = 0;
        commit;
    END del_transaction_type;
    PROCEDURE del_specific_app_type(id_i IN NUMBER)
    IS
    BEGIN
        delete from specific_applicability_types
        where id = id_i
        and status = 0;
        commit;
    END del_specific_app_type;
    PROCEDURE del_revenue_purpose(id_i IN NUMBER)
    IS
    BEGIN
        delete from revenue_purposes
        where id = id_i
        and status = 0;
        commit;
    END del_revenue_purpose;
    PROCEDURE del_currency(id_i IN NUMBER)
    IS
    BEGIN
        delete from currencies
        where id = id_i
        and status = 0;
        commit;
    END del_currency;
    PROCEDURE del_contact_type(id_i IN NUMBER)
    IS
    BEGIN
        delete from contact_types
        where id = id_i
        and status = 0;
        commit;
    END del_contact_type;
    PROCEDURE del_contact_use_type(id_i IN NUMBER)
    IS
    BEGIN
        delete from contact_usage_types
        where id = id_i
        and status = 0;
        commit;
    END del_contact_use_type;

    PROCEDURE del_change_reason(id_i IN NUMBER)
    IS
    BEGIN
        delete from change_reasons
        where id = id_i
        and status = 0;
        commit;
    END del_change_reason;
    PROCEDURE del_language(id_i IN NUMBER)
    IS
    BEGIN
        delete from languages
        where id = id_i
        and status = 0;
        commit;
    END del_language;
    PROCEDURE del_source_type(id_i IN NUMBER)
    IS
    BEGIN
        delete from source_types
        where id = id_i
        and status = 0;
        commit;
    END del_source_type;
    PROCEDURE del_assignment_type(id_i IN NUMBER)
    IS
    BEGIN
        delete from assignment_types
        where id = id_i
        and status = 0;
        commit;
    END del_assignment_type;
    PROCEDURE del_calculation_method(id_i IN NUMBER)
    IS
    BEGIN
        delete from calculation_methods
        where id = id_i
        and status = 0;
        commit;
    END del_calculation_method;
    PROCEDURE del_Taxability_Element(id_i IN NUMBER)
    IS
    BEGIN
        delete from Taxability_Elements
        where id = id_i
        and status = 0;
        commit;
    END del_Taxability_Element;
    PROCEDURE del_product_tree(id_i IN NUMBER)
    IS
    BEGIN
        delete from product_trees
        where id = id_i
        and status = 0;
        commit;
    END del_product_tree;
    PROCEDURE del_geo_area_category(id_i IN NUMBER)
    IS
    BEGIN
        delete from geo_area_categories
        where id = id_i
        and status = 0;
        commit;
    END del_geo_area_category;

	PROCEDURE jurisoption_name_lookup(name_id_io IN OUT NUMBER, name_code_i IN VARCHAR2, name_desc_i IN VARCHAR2,entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF name_id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM juris_option_name_lookups t
            WHERE name_id = name_id_io;
            IF (l_status = 0) THEN
                update juris_option_name_lookups
                set name_code = name_code_i, name_desc = name_desc_i,entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE name_id = name_id_io;
            END IF;
        ELSE
            INSERT INTO juris_option_name_lookups (name_code, name_desc,entered_by) VALUES ( name_code_i, name_desc_i,entered_by_i)  RETURNING name_id INTO name_id_io;
        END IF;
        COMMIT;
    END jurisoption_name_lookup;

	PROCEDURE jurisoption_condition_lookup(condition_id_io IN OUT NUMBER, condition_code_i IN VARCHAR2, condition_desc_i IN VARCHAR2,entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF condition_id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM juris_option_condition_lookups t
            WHERE condition_id = condition_id_io;
            IF (l_status = 0) THEN
                update juris_option_condition_lookups
                set condition_code = condition_code_i, condition_desc = condition_desc_i,entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE condition_id = condition_id_io;
            END IF;
        ELSE
            INSERT INTO juris_option_condition_lookups (condition_code, condition_desc,entered_by) VALUES ( condition_code_i, condition_desc_i,entered_by_i)  RETURNING condition_id INTO condition_id_io;
        END IF;
        COMMIT;
    END jurisoption_condition_lookup;

	PROCEDURE jurisoption_value_lookup(value_id_io IN OUT NUMBER, value_code_i IN VARCHAR2, value_desc_i IN VARCHAR2,entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF value_id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM juris_option_value_lookups t
            WHERE value_id = value_id_io;
            IF (l_status = 0) THEN
                update juris_option_value_lookups
                set value_code = value_code_i, value_desc = value_desc_i,entered_by = entered_by_i, entered_date = SYSTIMESTAMP WHERE value_id = value_id_io;
            END IF;
        ELSE
            INSERT INTO juris_option_value_lookups (value_code, value_desc,entered_by) VALUES ( value_code_i, value_desc_i,entered_by_i)  RETURNING value_id INTO value_id_io;
        END IF;
        COMMIT;
    END jurisoption_value_lookup;

	PROCEDURE juris_logic_group_lookup(id_io IN OUT NUMBER, juris_logic_group_name_i IN VARCHAR2,entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF id_io IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM juris_logic_group_lookups t
            WHERE id = id_io;
            IF (l_status = 0) THEN
                update juris_logic_group_lookups
                set juris_logic_group_name = juris_logic_group_name_i,entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE id = id_io;
            END IF;
        ELSE
            INSERT INTO juris_logic_group_lookups (juris_logic_group_name,entered_by) VALUES ( juris_logic_group_name_i,entered_by_i) RETURNING id INTO id_io;
        END IF;
        COMMIT;
    END juris_logic_group_lookup;

	PROCEDURE del_jurisoption_name_lookup(name_id_i IN NUMBER)
    IS
    BEGIN
        delete from juris_option_name_lookups
        where name_id = name_id_i
        and status = 0;
        commit;
    END del_jurisoption_name_lookup;

	PROCEDURE del_jurisoption_cond_lookup(condition_id_i IN NUMBER)
    IS
    BEGIN
        delete from juris_option_condition_lookups
        where condition_id = condition_id_i
        and status = 0;
        commit;
    END del_jurisoption_cond_lookup;

	PROCEDURE del_jurisoption_value_lookup(value_id_i IN NUMBER)
    IS
    BEGIN
        delete from juris_option_value_lookups
        where value_id = value_id_i
        and status = 0;
        commit;
    END del_jurisoption_value_lookup;

	PROCEDURE del_juris_logic_group_lookup(id_i IN NUMBER)
    IS
    BEGIN
        delete from juris_logic_group_lookups
        where id = id_i
        and status = 0;
        commit;
    END del_juris_logic_group_lookup;

    PROCEDURE JURISMSG_SEVERITY_LOOKUP(severity_id_i IN OUT NUMBER, severity_code_i IN VARCHAR2, severity_desc_i IN VARCHAR2, entered_by_i IN NUMBER)
    IS
        l_status NUMBER;
    BEGIN

        IF severity_id_i IS NOT NULL THEN
            SELECT status
            INTO l_status
            FROM JURIS_MSG_SEVERITY_LOOKUPS t
            WHERE severity_id = severity_id_i;
            IF (l_status = 0) THEN
                update JURIS_MSG_SEVERITY_LOOKUPS
                set severity_code = severity_code_i, severity_description = severity_desc_i,entered_by = entered_by_i, entered_date = SYSTIMESTAMP
                WHERE severity_id = severity_id_i;
            END IF;
        ELSE
            INSERT INTO JURIS_MSG_SEVERITY_LOOKUPS (severity_code, severity_description,entered_by) VALUES ( severity_code_i, severity_desc_i,entered_by_i)  RETURNING severity_id INTO severity_id_i;
        END IF;
        COMMIT;
    END JURISMSG_SEVERITY_LOOKUP;

    PROCEDURE del_jurismsg_severity_lookup(severity_id_i IN NUMBER)
    IS
    BEGIN
        delete from JURIS_MSG_SEVERITY_LOOKUPS
        where severity_id = severity_id_i
        and status = 0;
        commit;
    END del_jurismsg_severity_lookup;

END APPLICATION_VALUES;
/