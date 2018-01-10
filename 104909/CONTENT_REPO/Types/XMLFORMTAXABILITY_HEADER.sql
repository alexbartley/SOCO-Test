CREATE OR REPLACE TYPE content_repo."XMLFORMTAXABILITY_HEADER"                                          AS OBJECT
(
id NUMBER,
nkid NUMBER,
rid NUMBER,
next_rid NUMBER,
entity_rid NUMBER,
reference_code VARCHAR2(256),
calculation_method NUMBER,
input_recoverability NUMBER,
basis_percent NUMBER,
start_date DATE,
end_date DATE,
modified NUMBER,
deleted NUMBER,
taxation_type NUMBER,
specific_applicability_type NUMBER,
transaction_type NUMBER,
entered_by number,
jurisdiction_id number,
rw number,
all_taxes_apply number);
/