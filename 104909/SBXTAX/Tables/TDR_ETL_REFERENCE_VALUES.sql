CREATE TABLE sbxtax.tdr_etl_reference_values (
  ref_group_nkid NUMBER NOT NULL,
  item_nkid NUMBER NOT NULL,
  "VALUE" VARCHAR2(200 CHAR) NOT NULL,
  item_start_date DATE,
  item_end_date DATE,
  description VARCHAR2(200 CHAR)
) 
TABLESPACE ositax;