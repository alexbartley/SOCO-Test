CREATE GLOBAL TEMPORARY TABLE content_repo.tmp_delete (
  table_name VARCHAR2(50 BYTE) NOT NULL,
  primary_key NUMBER NOT NULL
)
ON COMMIT DELETE ROWS;