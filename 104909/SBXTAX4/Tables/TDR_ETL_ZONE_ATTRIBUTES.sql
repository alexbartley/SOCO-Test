CREATE TABLE sbxtax4.tdr_etl_zone_attributes (
  tmp_id NUMBER,
  code_2char VARCHAR2(2 CHAR),
  code_3char VARCHAR2(2 CHAR),
  code_fips VARCHAR2(100 CHAR),
  default_flag VARCHAR2(1 CHAR),
  reverse_flag VARCHAR2(1 CHAR),
  terminator_flag VARCHAR2(1 CHAR)
) 
TABLESPACE ositax;