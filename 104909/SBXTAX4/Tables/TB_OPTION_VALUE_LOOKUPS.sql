CREATE TABLE sbxtax4.tb_option_value_lookups (
  option_value_lookup_id NUMBER NOT NULL,
  option_lookup_id NUMBER NOT NULL,
  "VALUE" VARCHAR2(200 CHAR) NOT NULL,
  description VARCHAR2(200 CHAR),
  type_lookup_id NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;