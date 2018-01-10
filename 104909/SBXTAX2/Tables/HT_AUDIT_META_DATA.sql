CREATE TABLE sbxtax2.ht_audit_meta_data (
  audit_event_meta_datum_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(200 BYTE) NOT NULL,
  "VALUE" VARCHAR2(200 BYTE) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;