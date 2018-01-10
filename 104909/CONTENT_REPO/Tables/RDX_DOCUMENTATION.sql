CREATE TABLE content_repo.rdx_documentation (
  doc_key NUMBER NOT NULL,
  doc_name VARCHAR2(128 CHAR),
  file_size NUMBER,
  doc_file BLOB
) 
TABLESPACE content_repo
LOB (doc_file) STORE AS BASICFILE (
  ENABLE STORAGE IN ROW);