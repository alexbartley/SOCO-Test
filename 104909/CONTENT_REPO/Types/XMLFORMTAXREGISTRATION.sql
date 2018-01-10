CREATE OR REPLACE TYPE content_repo."XMLFORMTAXREGISTRATION"                                          AS OBJECT
( id NUMBER
, rid number
, administrator_id NUMBER
, registration_mask VARCHAR2(100)
, start_date DATE
, end_date DATE
, entered_by NUMBER
, nkid number
, deleted NUMBER
, modified NUMBER
)
/