CREATE TABLE sbxtax2.ht_date_determination_logic (
  created_by NUMBER(10),
  creation_date DATE,
  date_determination_logic_id NUMBER(10),
  date_expression VARCHAR2(2000 BYTE),
  description VARCHAR2(2000 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_dt_determination_logic_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;