CREATE TABLE content_repo.tag_entities_t (
  cid NUMBER NOT NULL,
  tag_entity_descr VARCHAR2(32 CHAR),
  tbl_name VARCHAR2(32 CHAR),
  PRIMARY KEY (cid) USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;