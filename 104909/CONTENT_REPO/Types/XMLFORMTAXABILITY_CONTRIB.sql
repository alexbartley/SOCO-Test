CREATE OR REPLACE TYPE content_repo."XMLFORMTAXABILITY_CONTRIB"                                          as Object
(
 contrib_id NUMBER,
 contrib_rid NUMBER,
 contrib_nkid NUMBER,
 name VARCHAR2(128),
 related_app_id NUMBER,
 reference_code varchar2(64),
 basis_value NUMBER,
 start_date DATE,
 end_date DATE,
 modified NUMBER,
 deleted NUMBER);
/