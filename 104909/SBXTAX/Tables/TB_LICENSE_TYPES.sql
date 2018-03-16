CREATE TABLE sbxtax.tb_license_types (
  license_type_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  "NAME" VARCHAR2(100 CHAR),
  default_term NUMBER(10),
  temporary_days_valid NUMBER,
  license_mask VARCHAR2(100 CHAR),
  description VARCHAR2(200 CHAR),
  end_date_required_flag VARCHAR2(1 CHAR),
  license_number_required_flag VARCHAR2(1 CHAR),
  physical_license_required_flag VARCHAR2(1 CHAR),
  threshold_type VARCHAR2(1 CHAR),
  "OPERATOR" VARCHAR2(15 CHAR),
  default_threshold_amount NUMBER(31,5),
  currency_id NUMBER,
  unit_of_measure_code VARCHAR2(25 CHAR),
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;