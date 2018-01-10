CREATE TABLE sbxtax2.ht_zone_match_patterns (
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  "PATTERN" VARCHAR2(50 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  "TYPE" VARCHAR2(2 BYTE),
  "VALUE" VARCHAR2(50 BYTE),
  zone_match_pattern_id NUMBER(10),
  aud_zone_match_pattern_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;