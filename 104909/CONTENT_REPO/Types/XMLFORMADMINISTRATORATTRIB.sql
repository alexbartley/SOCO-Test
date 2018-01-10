CREATE OR REPLACE TYPE content_repo."XMLFORMADMINISTRATORATTRIB"                                          AS OBJECT
( id number
, rid number
, administrator_id number
, attribute_id number
, value varchar2(4000)
, start_date date
, end_date date
, entered_by number
, nkid number 
, modified number
, deleted NUMBER);
/