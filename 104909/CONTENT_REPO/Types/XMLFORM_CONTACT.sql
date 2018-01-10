CREATE OR REPLACE TYPE content_repo."XMLFORM_CONTACT"                                          force AS OBJECT
(id number
, usage_order number
, contact_usage_id number
, contact_usage_type_id number
, contact_type_id number
, contact_details varchar2(500)
, contact_notes varchar2(4000)
, language_id number
, deleted number
, modified NUMBER
, status NUMBER
, start_date date
, end_date date
)
/