CREATE TABLE sbxtax4.tdr_etl_us_zone_authorities (
  "ID" NUMBER,
  "STATE" VARCHAR2(100 CHAR),
  county VARCHAR2(100 CHAR),
  city VARCHAR2(100 CHAR),
  postcode VARCHAR2(100 CHAR),
  plus4 VARCHAR2(100 CHAR),
  authority VARCHAR2(100 CHAR),
  source_db VARCHAR2(100 CHAR),
  change_type VARCHAR2(100 CHAR)
) 
TABLESPACE ositax;