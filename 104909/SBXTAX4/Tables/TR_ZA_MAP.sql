CREATE TABLE sbxtax4.tr_za_map (
  fips CHAR(10 BYTE) NOT NULL,
  zone_level_id NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  authority_name VARCHAR2(100 BYTE) NOT NULL,
  zone_name VARCHAR2(50 BYTE) NOT NULL
) 
TABLESPACE ositax;