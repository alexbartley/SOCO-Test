CREATE TABLE content_repo.impl_comm_data_t (
  process_id NUMBER,
  parent_id NUMBER,
  child_id NUMBER,
  offname VARCHAR2(256 BYTE),
  c_id NUMBER,
  jta_id NUMBER,
  impl NUMBER,
  jta_level NUMBER,
  rid NUMBER,
  tree_order NUMBER,
  h_code VARCHAR2(128 CHAR),
  commodity_name VARCHAR2(500 BYTE),
  commodity_code VARCHAR2(100 BYTE)
) 
TABLESPACE content_repo;