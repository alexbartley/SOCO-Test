CREATE TABLE sbxtax2.tb_established_zones (
  established_zone_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  zone_id NUMBER NOT NULL,
  established_type VARCHAR2(10 BYTE),
  tax_type VARCHAR2(100 BYTE),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  interstate_tax_type_override VARCHAR2(100 BYTE),
  start_date DATE DEFAULT TO_DATE('01/01/1900 12:00 AM', 'mm/dd/yyyy hh:mi am') NOT NULL,
  end_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;