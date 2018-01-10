CREATE OR REPLACE TYPE content_repo."XMLFORM_TAXESREPORTING"                                          AS OBJECT
  ( id NUMBER
  , rid NUMBER
  , nkid NUMBER
  , repcode VARCHAR2(100)
  , startdate DATE
  , enddate DATE
  , modified NUMBER
  , deleted NUMBER);
/