CREATE TABLE content_repo.imp_js_tree_build (
  j3key VARCHAR2(32 BYTE),
  parent_id NUMBER,
  child_id NUMBER,
  offname VARCHAR2(256 BYTE),
  j_level NUMBER
) 
TABLESPACE content_repo;