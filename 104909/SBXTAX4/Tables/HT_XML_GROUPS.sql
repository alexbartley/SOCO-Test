CREATE TABLE sbxtax4.ht_xml_groups (
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  xml_group_id NUMBER(10),
  xml_group_name VARCHAR2(100 BYTE),
  aud_xml_group_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;