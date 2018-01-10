CREATE TABLE content_repo.tdr_etl_extract_list (
  extraction_id NUMBER NOT NULL,
  entity VARCHAR2(128 CHAR) NOT NULL,
  rid NUMBER NOT NULL,
  queue_id NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  tag_list VARCHAR2(200 BYTE)
) 
TABLESPACE content_repo;