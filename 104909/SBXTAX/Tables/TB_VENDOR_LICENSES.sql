CREATE TABLE sbxtax.tb_vendor_licenses (
  vendor_license_id NUMBER NOT NULL,
  license_type_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  license_number VARCHAR2(100 CHAR),
  external_identifier VARCHAR2(100 CHAR),
  temporary_license_flag VARCHAR2(1 CHAR),
  start_date DATE NOT NULL,
  end_date DATE,
  threshold_amount NUMBER(31,5),
  currency_id NUMBER,
  unit_of_measure_code VARCHAR2(25 CHAR),
  license_url VARCHAR2(1000 CHAR),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;