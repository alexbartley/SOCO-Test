CREATE TABLE sbxtax3.tb_license_types (
  license_type_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(100 BYTE),
  default_term NUMBER(10),
  temporary_days_valid NUMBER(10),
  license_mask VARCHAR2(100 BYTE),
  description VARCHAR2(200 BYTE),
  end_date_required_flag VARCHAR2(1 BYTE),
  license_number_required_flag VARCHAR2(1 BYTE),
  physical_license_required_flag VARCHAR2(1 BYTE),
  threshold_type VARCHAR2(1 BYTE),
  "OPERATOR" VARCHAR2(15 BYTE),
  default_threshold_amount NUMBER(31,5),
  currency_id NUMBER(10),
  unit_of_measure_code VARCHAR2(25 BYTE),
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;