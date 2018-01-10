CREATE OR REPLACE PACKAGE content_repo."APPLICATION_VALUES"
  IS
    --Tags
    PROCEDURE user_tag(id_io IN OUT NUMBER, name_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE del_user_tag(id_i IN NUMBER);

    --Attributes
    PROCEDURE attribute_category(id_io IN OUT NUMBER, name_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE additional_attribute(id_io IN OUT NUMBER, name_i IN VARCHAR2, purpose_i IN VARCHAR2, att_cat_id_i IN NUMBER, entered_by_i IN NUMBER);
    PROCEDURE attribute_lookup(id_io IN OUT NUMBER, value_i IN VARCHAR2, att_id_i IN NUMBER, entered_by_i IN NUMBER);
    PROCEDURE del_attribute_category(id_i IN NUMBER);
    PROCEDURE del_additional_attribute(id_i IN NUMBER);

    --Tax Categorization
    PROCEDURE taxation_type(id_io IN OUT NUMBER, name_i IN VARCHAR2, description_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE transaction_type(id_io IN OUT NUMBER, name_i IN VARCHAR2, description_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE specific_app_type(id_io IN OUT NUMBER, name_i IN VARCHAR2, description_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE del_taxation_type(id_i IN NUMBER);
    PROCEDURE del_transaction_type(id_i IN NUMBER);
    PROCEDURE del_specific_app_type(id_i IN NUMBER);

    --Taxes
    PROCEDURE revenue_purpose(id_io IN OUT NUMBER, name_i IN VARCHAR2, description_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE currency(id_io IN OUT NUMBER, code_i IN VARCHAR2, description_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE del_revenue_purpose(id_i IN NUMBER);
    PROCEDURE del_currency(id_i IN NUMBER);

    --Contacts
    PROCEDURE contact_type(id_io IN OUT NUMBER, name_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE contact_usage_type(id_io IN OUT NUMBER, name_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE del_contact_type(id_i IN NUMBER);
    PROCEDURE del_contact_use_type(id_i IN NUMBER);

    --Documentation
    PROCEDURE Language(id_io IN OUT NUMBER, name_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE Source_Type(id_io IN OUT NUMBER, name_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE del_language(id_i IN NUMBER);
    PROCEDURE del_source_type(id_i IN NUMBER);

    --Change Log
    PROCEDURE change_reason(id_io IN OUT NUMBER, name_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE Assignment_Type(id_io IN OUT NUMBER, name_i IN VARCHAR2, ui_order_i IN NUMBER, entered_by_i IN NUMBER);
    PROCEDURE del_change_reason(id_i IN NUMBER);
    PROCEDURE del_Assignment_Type(id_i IN NUMBER);

    --Taxability
    PROCEDURE Calculation_Method(id_io IN OUT NUMBER, name_i IN VARCHAR2, description_i IN VARCHAR2, ui_order_i IN NUMBER, entered_by_i IN NUMBER);
    PROCEDURE Taxability_Element(id_io IN OUT NUMBER, element_name_i IN VARCHAR2,  description_i IN VARCHAR2, value_type_i IN VARCHAR2,entered_by_i IN NUMBER);
    PROCEDURE del_Calculation_Method(id_i IN NUMBER);
    PROCEDURE del_Taxability_Element(id_i IN NUMBER);

    --Commodity
    PROCEDURE Product_Tree(id_io IN OUT NUMBER, name_i IN VARCHAR2, short_name_i IN VARCHAR2, entered_by_i IN NUMBER);
    PROCEDURE del_Product_Tree(id_i IN NUMBER);

    --GIS
    --PROCEDURE Geo_Area_Categories
    PROCEDURE Geo_Area_Category(id_io IN OUT NUMBER, name_i IN VARCHAR2, ui_order_i IN NUMBER, entered_by_i IN NUMBER);
    PROCEDURE del_Geo_Area_Category(id_i IN NUMBER);

	-- Procedures added as part of CRAPP-3627
	-- Options
	PROCEDURE jurisoption_name_lookup(name_id_io IN OUT NUMBER, name_code_i IN VARCHAR2, name_desc_i IN VARCHAR2,entered_by_i IN NUMBER);
	PROCEDURE jurisoption_condition_lookup(condition_id_io IN OUT NUMBER, condition_code_i IN VARCHAR2, condition_desc_i IN VARCHAR2,entered_by_i IN NUMBER);
	PROCEDURE jurisoption_value_lookup(value_id_io IN OUT NUMBER, value_code_i IN VARCHAR2, value_desc_i IN VARCHAR2,entered_by_i IN NUMBER);
	PROCEDURE del_jurisoption_name_lookup(name_id_i IN NUMBER);
	PROCEDURE del_jurisoption_cond_lookup(condition_id_i IN NUMBER);
	PROCEDURE del_jurisoption_value_lookup(value_id_i IN NUMBER);

	-- Logic mapping
	PROCEDURE juris_logic_group_lookup(id_io IN OUT NUMBER, juris_logic_group_name_i IN VARCHAR2,entered_by_i IN NUMBER);
	PROCEDURE del_juris_logic_group_lookup(id_i IN NUMBER);

	-- Procedures added as part of CRAPP-3689
	-- messages

	PROCEDURE JURISMSG_SEVERITY_LOOKUP(severity_id_i IN OUT NUMBER, severity_code_i IN VARCHAR2, severity_desc_i IN VARCHAR2, entered_by_i IN NUMBER);
	PROCEDURE del_juris_msg_severity_lookup(severity_id_i IN NUMBER);

END APPLICATION_VALUES;
/