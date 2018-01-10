CREATE OR REPLACE TYPE content_repo."XMLFORMTAXDESCRIPTION"                                          AS OBJECT
( id number
, tax_description_id number
, taxation_type_id number
, spec_app_type_id number
, tran_type_id number
, entered_by number
, deleted NUMBER
, modified NUMBER
, start_date date
, end_date date
)
/