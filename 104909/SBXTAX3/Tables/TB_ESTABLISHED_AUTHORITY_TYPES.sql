CREATE TABLE sbxtax3.tb_established_authority_types (
  established_auth_type_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  established_zone_id NUMBER(10) NOT NULL,
  authority_type_id NUMBER(10) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  default_established VARCHAR2(1 BYTE),
  default_tax_type VARCHAR2(100 BYTE),
  interstate_tax_type_override VARCHAR2(100 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;