CREATE OR REPLACE TYPE content_repo."XMLFORM_EXTERNAL_REF"                                          AS OBJECT                                  
(
  id NUMBER
 , ref_system NUMBER
 , ref_id varchar2(64)
 , ext_link varchar2(2048)
 , deleted NUMBER
 , modified NUMBER
)
/