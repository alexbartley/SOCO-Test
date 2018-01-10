CREATE TABLE sbxtax4.tdr_etl_reference_lists (
  ref_group_nkid NUMBER,
  "NAME" VARCHAR2(100 CHAR),
  "VALUE" VARCHAR2(128 CHAR),
  list_start_date DATE,
  list_end_date DATE,
  item_start_date DATE,
  item_end_date DATE,
  extract_id NUMBER,
  description VARCHAR2(800 CHAR),
  nkid NUMBER,
  rid NUMBER,
  item_nkid NUMBER
) 
TABLESPACE ositax;