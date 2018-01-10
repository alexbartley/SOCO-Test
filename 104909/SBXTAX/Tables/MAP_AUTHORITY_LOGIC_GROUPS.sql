CREATE TABLE sbxtax.map_authority_logic_groups (
  "STATE" VARCHAR2(8 BYTE),
  effective_zone_level VARCHAR2(50 BYTE) NOT NULL,
  authority_logic_group_id NUMBER NOT NULL,
  authority_logic_group VARCHAR2(100 BYTE) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  process_order NUMBER NOT NULL,
  authority_type VARCHAR2(100 CHAR)
) 
TABLESPACE ositax;