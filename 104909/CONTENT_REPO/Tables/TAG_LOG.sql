CREATE TABLE content_repo.tag_log (
  entity NUMBER NOT NULL,
  entered_by NUMBER NOT NULL,
  tag_action VARCHAR2(6 CHAR),
  tag_id NUMBER,
  nkid NUMBER,
  refid NUMBER,
  entered_date TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE content_repo;