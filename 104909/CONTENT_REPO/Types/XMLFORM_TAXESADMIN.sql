CREATE OR REPLACE TYPE content_repo."XMLFORM_TAXESADMIN"                                          AS OBJECT
  ( id NUMBER
  , rid NUMBER
  , nkid number
  , administrator_id number
  , admincollects number
  , admincollector varchar2(100)
  , admin_start date
  , admin_end date
  , modified number
  , deleted NUMBER);
/