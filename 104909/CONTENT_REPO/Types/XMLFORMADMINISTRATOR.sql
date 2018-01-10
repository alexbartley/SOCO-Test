CREATE OR REPLACE TYPE content_repo."XMLFORMADMINISTRATOR"                                          AS OBJECT
( id number
, rid number
, name varchar2(250)
, start_date date
, end_date date
, entered_by number
, nkid number
, description VARCHAR2(250)
, requires_registration number
, collects_tax number
, notes VARCHAR2(4000)
, administrator_type_id number
, modified number
, deleted NUMBER);
/