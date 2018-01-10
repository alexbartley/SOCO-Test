CREATE OR REPLACE TYPE content_repo."XMLFORM_TAXESDEFINE"                                          AS OBJECT
  ( id NUMBER
  , rid NUMBER
  , nkid NUMBER
  , jurisdiction_id number
  , taxdescriptionid number
  , revenuepurpose number
  , referencecode varchar2(50)
  , calculationstructureid number
  , description varchar2(250)
  , startdate date
  , enddate date
  , enteredby number
  , modified number
  , deleted number
  );
/