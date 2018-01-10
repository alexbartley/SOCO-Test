CREATE TABLE sbxtax2.a_zone_match_contexts (
  zone_match_context_id NUMBER(10),
  zone_match_pattern_id NUMBER(10),
  zone_level_id NUMBER(10),
  zone_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP,
  zone_match_context_id_o NUMBER(10),
  zone_match_pattern_id_o NUMBER(10),
  zone_level_id_o NUMBER(10),
  zone_id_o NUMBER(10),
  created_by_o NUMBER(10),
  creation_date_o DATE,
  last_updated_by_o NUMBER(10),
  last_update_date_o DATE,
  synchronization_timestamp_o TIMESTAMP,
  change_version VARCHAR2(50 BYTE),
  change_type VARCHAR2(100 BYTE) NOT NULL,
  change_date DATE NOT NULL
) 
TABLESPACE ositax;