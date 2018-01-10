CREATE TABLE content_repo.tdr_etl_tag_groups (
  "ID" NUMBER NOT NULL,
  tag_group_name VARCHAR2(128 CHAR) NOT NULL,
  sort_order NUMBER,
  CONSTRAINT tdr_etl_tag_groups_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo;