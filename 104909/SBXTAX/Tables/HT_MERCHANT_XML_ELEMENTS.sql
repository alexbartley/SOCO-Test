CREATE TABLE sbxtax.ht_merchant_xml_elements (
  created_by NUMBER(10),
  creation_date DATE,
  is_returned VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_xml_element_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  xml_element_id NUMBER(10),
  xml_group_id NUMBER(10),
  aud_merchant_xml_element_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;