CREATE OR REPLACE TYPE content_repo."XMLFORM_TAXESATTRIB"                                          AS OBJECT
  ( id NUMBER              -- TAX_ATTRIBUTES.attribute_id
  , rid NUMBER
  , nkid NUMBER
  , attribute_id NUMBER
  , aname  VARCHAR2(100)
  , avalue VARCHAR2(1000)  -- TAX_ATTRIBUTES.value
  , attrStartDate DATE
  , attrEndDate DATE
  , modified NUMBER
  , deleted NUMBER);
/