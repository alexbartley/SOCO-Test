CREATE TABLE sbxtax.tb_zone_match_patterns (
  zone_match_pattern_id NUMBER NOT NULL,
  "PATTERN" VARCHAR2(50 CHAR) NOT NULL,
  "VALUE" VARCHAR2(50 CHAR) NOT NULL,
  "TYPE" VARCHAR2(2 CHAR) NOT NULL,
  merchant_id NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;