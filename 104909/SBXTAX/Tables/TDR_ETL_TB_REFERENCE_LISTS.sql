CREATE TABLE sbxtax.tdr_etl_tb_reference_lists (
  "NAME" VARCHAR2(100 CHAR),
  start_date DATE,
  end_date DATE,
  ref_group_nkid NUMBER,
  description VARCHAR2(800 CHAR),
  nkid NUMBER,
  rid NUMBER,
  reference_list_id NUMBER
) 
TABLESPACE ositax;