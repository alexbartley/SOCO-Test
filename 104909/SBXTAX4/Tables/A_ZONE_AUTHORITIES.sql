CREATE TABLE sbxtax4.a_zone_authorities (
  zone_authority_id NUMBER,
  zone_id NUMBER,
  authority_id NUMBER,
  created_by NUMBER,
  creation_date DATE,
  last_updated_by NUMBER,
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP,
  zone_authority_id_o NUMBER,
  zone_id_o NUMBER,
  authority_id_o NUMBER,
  created_by_o NUMBER,
  creation_date_o DATE,
  last_updated_by_o NUMBER,
  last_update_date_o DATE,
  synchronization_timestamp_o TIMESTAMP,
  change_type VARCHAR2(20 CHAR) NOT NULL,
  change_version VARCHAR2(50 CHAR),
  change_date DATE NOT NULL
) 
TABLESPACE ositax;