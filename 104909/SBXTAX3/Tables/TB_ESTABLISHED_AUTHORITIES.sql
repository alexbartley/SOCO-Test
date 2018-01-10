CREATE TABLE sbxtax3.tb_established_authorities (
  established_authority_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  established_authority_type_id NUMBER(10) NOT NULL,
  authority_id NUMBER(10) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  established VARCHAR2(1 BYTE),
  tax_type VARCHAR2(100 BYTE),
  interstate_tax_type_override VARCHAR2(100 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;