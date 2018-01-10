CREATE TABLE content_repo.commodities_pctree (
  "ID" NUMBER NOT NULL,
  rid NUMBER NOT NULL,
  next_rid NUMBER,
  nkid NUMBER NOT NULL,
  product_tree_id NUMBER NOT NULL,
  h_code VARCHAR2(128 CHAR),
  parent_h_code VARCHAR2(32767 CHAR),
  child_h_code VARCHAR2(128 CHAR),
  level_id NUMBER,
  "NAME" VARCHAR2(500 BYTE) NOT NULL,
  description VARCHAR2(1000 CHAR),
  commodity_code VARCHAR2(100 CHAR),
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  status NUMBER NOT NULL,
  status_modified_date TIMESTAMP,
  start_date DATE,
  end_date DATE
) 
TABLESPACE content_repo
LOB (parent_h_code) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);