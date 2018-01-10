CREATE OR REPLACE TYPE content_repo."XMLFORM_CITATION"                                          AS OBJECT                                  
( id number
, text varchar2(4000)
, attachment_id number
, deleted number
)
/