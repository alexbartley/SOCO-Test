CREATE TABLE content_repo.juris_type_qr (
  "ID" NUMBER NOT NULL,
  ref_rid NUMBER NOT NULL,
  ref_id NUMBER NOT NULL,
  ref_nkid NUMBER NOT NULL,
  table_name VARCHAR2(30 CHAR) NOT NULL,
  qr VARCHAR2(256 CHAR) NOT NULL,
  entered_date DATE NOT NULL,
  entered_by NUMBER NOT NULL,
  CONSTRAINT juris_type_qr_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;