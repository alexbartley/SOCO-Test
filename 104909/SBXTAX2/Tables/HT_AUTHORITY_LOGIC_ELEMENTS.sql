CREATE TABLE sbxtax2.ht_authority_logic_elements (
  authority_logic_element_id NUMBER(10),
  authority_logic_group_id NUMBER(10),
  "CONDITION" VARCHAR2(10 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  selector VARCHAR2(10 BYTE),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  "VALUE" NUMBER(10),
  aud_authority_logic_element_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;