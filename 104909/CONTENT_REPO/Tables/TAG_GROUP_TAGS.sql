CREATE TABLE content_repo.tag_group_tags (
  tag_group_id NUMBER NOT NULL,
  tag_group_name VARCHAR2(128 CHAR) NOT NULL,
  tag_list VARCHAR2(32767 CHAR),
  CONSTRAINT tag_group_tags_pk PRIMARY KEY (tag_group_id) USING INDEX 
    TABLESPACE content_repo
) 
TABLESPACE content_repo
LOB (tag_list) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);