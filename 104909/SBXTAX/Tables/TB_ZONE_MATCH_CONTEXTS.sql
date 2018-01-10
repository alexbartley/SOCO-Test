CREATE TABLE sbxtax.tb_zone_match_contexts (
  zone_match_context_id NUMBER NOT NULL,
  zone_match_pattern_id NUMBER NOT NULL,
  zone_level_id NUMBER NOT NULL,
  zone_id NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;