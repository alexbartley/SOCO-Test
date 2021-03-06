CREATE TABLE sbxtax3.tb_exempt_certs (
  exempt_cert_id NUMBER(10) NOT NULL,
  certificate_comment VARCHAR2(2000 BYTE),
  customer_id NUMBER(10) NOT NULL,
  certificate_number VARCHAR2(100 BYTE),
  purch_license_number VARCHAR2(100 BYTE),
  purch_reg_tax_id VARCHAR2(100 BYTE),
  seller_name VARCHAR2(100 BYTE),
  seller_number VARCHAR2(100 BYTE),
  seller_dba_name VARCHAR2(100 BYTE),
  seller_license_number VARCHAR2(100 BYTE),
  seller_reg_tax_id VARCHAR2(100 BYTE),
  cert_use VARCHAR2(1 BYTE) NOT NULL,
  from_date DATE NOT NULL,
  "TO_DATE" DATE,
  exempt_reason_id NUMBER(10),
  fully_exempt VARCHAR2(1 BYTE),
  "ACTIVE" VARCHAR2(1 BYTE),
  status VARCHAR2(1 BYTE) NOT NULL,
  type_of_business VARCHAR2(200 BYTE),
  prod_incl_excl_flag VARCHAR2(1 BYTE),
  file_id NUMBER(10),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  basis_perc NUMBER(31,10),
  currency_id NUMBER(10),
  exempt_amount NUMBER(31,5),
  cert_url VARCHAR2(1000 BYTE),
  content_type VARCHAR2(50 BYTE) NOT NULL,
  "LOCKED" VARCHAR2(1 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;