CREATE TABLE sbxtax2.ht_tax_code_qualifiers (
  concatenation_delimiter VARCHAR2(1 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  erp_tax_code VARCHAR2(200 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "NAME" VARCHAR2(100 BYTE),
  ordering NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  tax_code_qualifier_group_id NUMBER(10),
  tax_code_qualifier_id NUMBER(10),
  aud_tax_code_qualifier_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;