CREATE TABLE sbxtax.tdr_etl_tb_auth_logic_groups (
  authority_uuid VARCHAR2(36 CHAR),
  authority_logic_group_id NUMBER,
  start_date DATE,
  end_date DATE,
  process_order NUMBER,
  nkid NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;