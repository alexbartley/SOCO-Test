CREATE TABLE content_repo.copy_to_tmp (
  process_id NUMBER,
  juris_id NUMBER,
  copyto VARCHAR2(4000 BYTE),
  copyfrom VARCHAR2(4000 BYTE),
  copyfromstart DATE,
  copyfromend DATE
) 
TABLESPACE content_repo;