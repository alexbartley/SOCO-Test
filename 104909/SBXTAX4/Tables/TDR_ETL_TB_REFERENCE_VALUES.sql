CREATE TABLE sbxtax4.tdr_etl_tb_reference_values (
  reference_list_id NUMBER,
  ref_group_nkid NUMBER,
  "VALUE" VARCHAR2(800 CHAR),
  start_date DATE,
  end_date DATE,
  reference_value_id NUMBER,
  nkid NUMBER,
  rid NUMBER,
  item_nkid NUMBER
) 
TABLESPACE ositax;