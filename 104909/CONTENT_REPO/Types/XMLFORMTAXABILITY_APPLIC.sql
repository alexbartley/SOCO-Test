CREATE OR REPLACE TYPE content_repo."XMLFORMTAXABILITY_APPLIC"                                          as Object
(Id NUMBER,
Nkid NUMBER,
Rid  NUMBER,
entity_rid NUMBER,
next_rid  NUMBER,
jurisdiction_id NUMBER,
tax_description_id NUMBER,
reference_code VARCHAR2(50), --imp_ref_code
start_date date,
end_date date,
description VARCHAR2(256),
status NUMBER,
entered_by NUMBER,
revenue_purpose_id NUMBER,
revenue_purpose_name varchar2(256),
modified NUMBER,
deleted NUMBER,
tax_definition_collection NUMBER,
reporting_code_collection NUMBER,
administrator_collection NUMBER,
attribute_collection NUMBER,
juris_tax_imposition_id NUMBER,
tax_applicability_id_list varchar2(4000)
);
/