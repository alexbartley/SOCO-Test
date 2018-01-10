CREATE OR REPLACE TYPE content_repo."XMLFORM_TAXESOUTLINE"                                          AS OBJECT
  ( id NUMBER
  , rid NUMBER
  , nkid NUMBER
  , calculationstructureid number
  , startdate date
  , enddate date
  , modified number
  , deleted number
  , threshxml XMLType
  );
/