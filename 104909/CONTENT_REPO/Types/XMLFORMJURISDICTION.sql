CREATE OR REPLACE TYPE content_repo.xmlformjurisdiction                                          AS OBJECT
( id number
, rid number
, official_name varchar2(250)
, start_date date
, end_date date
, entered_by number
, nkid number
, description VARCHAR2(1000)
, currency_id number
, location_category_id number
, modified number
, deleted NUMBER
, default_admin_id number
, jurisdiction_type_id number);
/