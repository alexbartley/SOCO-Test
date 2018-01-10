CREATE TABLE sbxtax2.tb_acd_events (
  event_id NUMBER(10) NOT NULL,
  subject_id NUMBER(10) NOT NULL,
  event_classification NUMBER(10) NOT NULL,
  occurrence_count NUMBER(10) NOT NULL,
  event_metadata VARCHAR2(1024 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;