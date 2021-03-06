CREATE TABLE sbxtax.ht_license_types (
  created_by NUMBER(10),
  creation_date DATE,
  currency_id NUMBER(10),
  default_term NUMBER(10),
  default_threshold_amount NUMBER(31,5),
  description VARCHAR2(200 BYTE),
  end_date DATE,
  end_date_required_flag VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  license_mask VARCHAR2(100 BYTE),
  license_number_required_flag VARCHAR2(1 BYTE),
  license_type_id NUMBER(10),
  merchant_id NUMBER(10),
  "NAME" VARCHAR2(100 BYTE),
  "OPERATOR" VARCHAR2(15 BYTE),
  physical_license_required_flag VARCHAR2(1 BYTE),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  temporary_days_valid NUMBER(10),
  threshold_type VARCHAR2(1 BYTE),
  unit_of_measure_code VARCHAR2(25 BYTE),
  aud_license_type_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;