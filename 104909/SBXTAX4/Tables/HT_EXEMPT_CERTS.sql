CREATE TABLE sbxtax4.ht_exempt_certs (
  "ACTIVE" VARCHAR2(1 BYTE),
  basis_perc NUMBER(31,10),
  certificate_comment VARCHAR2(2000 BYTE),
  certificate_number VARCHAR2(100 BYTE),
  cert_url VARCHAR2(1000 BYTE),
  cert_use VARCHAR2(1 BYTE),
  content_type VARCHAR2(50 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  currency_id NUMBER(10),
  customer_id NUMBER(10),
  exempt_amount NUMBER(31,5),
  exempt_cert_id NUMBER(10),
  exempt_reason_id NUMBER(10),
  file_id NUMBER(10),
  from_date DATE,
  fully_exempt VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  "LOCKED" VARCHAR2(1 BYTE),
  prod_incl_excl_flag VARCHAR2(1 BYTE),
  purch_license_number VARCHAR2(100 BYTE),
  purch_reg_tax_id VARCHAR2(100 BYTE),
  seller_dba_name VARCHAR2(100 BYTE),
  seller_license_number VARCHAR2(100 BYTE),
  seller_name VARCHAR2(100 BYTE),
  seller_number VARCHAR2(100 BYTE),
  seller_reg_tax_id VARCHAR2(100 BYTE),
  status VARCHAR2(1 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  "TO_DATE" DATE,
  type_of_business VARCHAR2(200 BYTE),
  aud_exempt_cert_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;