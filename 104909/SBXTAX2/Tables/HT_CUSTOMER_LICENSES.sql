CREATE TABLE sbxtax2.ht_customer_licenses (
  created_by NUMBER(10),
  creation_date DATE,
  currency_id NUMBER(10),
  customer_id NUMBER(10),
  customer_license_id NUMBER(10),
  end_date DATE,
  external_identifier VARCHAR2(100 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  license_number VARCHAR2(100 BYTE),
  license_type_id NUMBER(10),
  license_url VARCHAR2(1000 BYTE),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  temporary_license_flag VARCHAR2(1 BYTE),
  threshold_amount NUMBER(31,5),
  unit_of_measure_code VARCHAR2(25 BYTE),
  aud_customer_license_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;