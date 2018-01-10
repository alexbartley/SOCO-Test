CREATE TABLE sbxtax2.tb_merchant_options (
  merchant_option_id NUMBER(10) NOT NULL,
  merchant_id NUMBER(10) NOT NULL,
  option_lookup_id NUMBER(10) NOT NULL,
  "VALUE" VARCHAR2(200 BYTE) NOT NULL,
  type_lookup_id NUMBER(10),
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;