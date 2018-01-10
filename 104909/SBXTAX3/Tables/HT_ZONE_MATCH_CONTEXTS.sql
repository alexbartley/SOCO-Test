CREATE TABLE sbxtax3.ht_zone_match_contexts (
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  zone_id NUMBER(10),
  zone_level_id NUMBER(10),
  zone_match_context_id NUMBER(10),
  zone_match_pattern_id NUMBER(10),
  aud_zone_match_context_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;