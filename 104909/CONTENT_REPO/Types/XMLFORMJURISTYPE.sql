CREATE OR REPLACE TYPE content_repo.xmlformjuristype                                          AS OBJECT
( id number
, rid number
, name varchar2(250)
, start_date date
, end_date date
, entered_by number
, nkid number
, description VARCHAR2(250)
, modified number
, deleted NUMBER);
/