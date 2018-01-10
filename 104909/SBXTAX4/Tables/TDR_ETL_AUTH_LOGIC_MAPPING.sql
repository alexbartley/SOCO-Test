CREATE TABLE sbxtax4.tdr_etl_auth_logic_mapping (
  nkid NUMBER NOT NULL,
  authority_logic_group_id NUMBER NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  process_order NUMBER NOT NULL,
  rid NUMBER
) 
TABLESPACE ositax;