CREATE TABLE sbxtax4.ht_filter_conditions (
  condition_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  filter_id NUMBER(10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "OPERATOR" VARCHAR2(15 BYTE),
  ordering NUMBER(10),
  parent_condition_id NUMBER(10),
  reference_list_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  "VALUE" VARCHAR2(250 BYTE),
  value_xml_element VARCHAR2(1500 BYTE),
  xml_element VARCHAR2(1500 BYTE),
  aud_filter_condition_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;