CREATE TABLE content_repo.commodities (
  "ID" NUMBER NOT NULL,
  "NAME" VARCHAR2(500 BYTE) NOT NULL,
  description VARCHAR2(1000 CHAR),
  commodity_code VARCHAR2(100 CHAR),
  entered_by NUMBER NOT NULL,
  entered_date TIMESTAMP NOT NULL,
  rid NUMBER NOT NULL,
  nkid NUMBER NOT NULL,
  next_rid NUMBER,
  status NUMBER DEFAULT 0 NOT NULL,
  status_modified_date TIMESTAMP,
  product_tree_id NUMBER NOT NULL,
  start_date DATE,
  end_date DATE,
  h_code VARCHAR2(128 CHAR),
  CONSTRAINT commodities_pk PRIMARY KEY ("ID") USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT commodities_un UNIQUE (nkid,rid) USING INDEX 
    TABLESPACE content_repo,
  CONSTRAINT comm_prod_tree_fk FOREIGN KEY (product_tree_id) REFERENCES content_repo.product_trees ("ID")
) 
TABLESPACE content_repo;