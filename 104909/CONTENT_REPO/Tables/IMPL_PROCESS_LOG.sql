CREATE TABLE content_repo.impl_process_log (
  processid NUMBER NOT NULL,
  processtime DATE,
  stage NUMBER,
  message VARCHAR2(50 BYTE),
  PRIMARY KEY (processid) USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;