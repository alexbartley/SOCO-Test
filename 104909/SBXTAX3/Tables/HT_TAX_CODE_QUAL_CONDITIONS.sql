CREATE TABLE sbxtax3.ht_tax_code_qual_conditions (
  concatenation_value VARCHAR2(200 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "OPERATOR" VARCHAR2(15 BYTE),
  ordering NUMBER(10),
  reference_list_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  tax_code_qualifier_id NUMBER(10),
  tax_code_qual_condition_id NUMBER(10),
  use_delimiter VARCHAR2(1 BYTE),
  "VALUE" VARCHAR2(250 BYTE),
  xml_element VARCHAR2(100 BYTE),
  aud_tax_code_qual_condition_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;