CREATE TABLE content_repo.copy_taxabilities_a (
  jurisdiction_nkid NUMBER NOT NULL,
  process_copy_id NUMBER NOT NULL,
  stepstatus NUMBER NOT NULL,
  objtype VARCHAR2(1 BYTE),
  entered_by NUMBER
) 
TABLESPACE content_repo;