CREATE TABLE sbxtax2.tb_customer_licenses (
  customer_license_id NUMBER(10) NOT NULL,
  license_type_id NUMBER(10) NOT NULL,
  customer_id NUMBER(10) NOT NULL,
  license_number VARCHAR2(100 BYTE),
  external_identifier VARCHAR2(100 BYTE),
  temporary_license_flag VARCHAR2(1 BYTE),
  start_date DATE NOT NULL,
  end_date DATE,
  threshold_amount NUMBER(31,5),
  currency_id NUMBER(10),
  unit_of_measure_code VARCHAR2(25 BYTE),
  license_url VARCHAR2(1000 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;