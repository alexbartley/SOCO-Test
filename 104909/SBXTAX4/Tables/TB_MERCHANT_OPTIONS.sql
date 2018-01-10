CREATE TABLE sbxtax4.tb_merchant_options (
  merchant_option_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  option_lookup_id NUMBER NOT NULL,
  "VALUE" VARCHAR2(200 CHAR) NOT NULL,
  type_lookup_id NUMBER,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;