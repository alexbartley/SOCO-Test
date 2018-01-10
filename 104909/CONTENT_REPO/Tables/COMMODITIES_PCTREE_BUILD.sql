CREATE TABLE content_repo.commodities_pctree_build (
  ccc_level NUMBER,
  h_code_level NUMBER,
  commtree VARCHAR2(256 CHAR),
  "NAME" VARCHAR2(500 BYTE) NOT NULL,
  leaf NUMBER,
  parent_h_code VARCHAR2(128 CHAR),
  child_h_code VARCHAR2(128 CHAR),
  nkid NUMBER NOT NULL,
  commodity_id NUMBER NOT NULL,
  commodity_code VARCHAR2(100 CHAR),
  product_tree_id NUMBER NOT NULL,
  c_id NUMBER
) 
TABLESPACE content_repo;