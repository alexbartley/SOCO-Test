CREATE TABLE sbxtax4.pvw_tb_zones (
  zone_id NUMBER NOT NULL,
  "NAME" VARCHAR2(50 CHAR) NOT NULL,
  parent_zone_id NUMBER,
  merchant_id NUMBER NOT NULL,
  zone_level_id NUMBER,
  eu_zone_as_of_date DATE,
  reverse_flag VARCHAR2(1 CHAR),
  terminator_flag VARCHAR2(1 CHAR),
  default_flag VARCHAR2(1 CHAR),
  range_min NUMBER,
  range_max NUMBER,
  tax_parent_zone_id NUMBER,
  code_2char VARCHAR2(2 CHAR),
  code_3char VARCHAR2(3 CHAR),
  code_iso VARCHAR2(3 CHAR),
  code_fips VARCHAR2(30 CHAR),
  synchronization_timestamp TIMESTAMP
) 
TABLESPACE ositax;