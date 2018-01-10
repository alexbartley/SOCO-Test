CREATE OR REPLACE TYPE content_repo."XMLFORMJURISDICTIONATTRIB"                                          AS OBJECT
( id number
, rid number
, jurisdiction_id number
, attribute_id number
, value varchar2(4000)
, value_id number
, start_date date
, end_date date
, entered_by number
, nkid number 
, modified number
, deleted NUMBER);
/