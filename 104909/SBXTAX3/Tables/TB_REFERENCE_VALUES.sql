CREATE TABLE sbxtax3.tb_reference_values (
  reference_value_id NUMBER(10) NOT NULL,
  reference_list_id NUMBER(10) NOT NULL,
  "VALUE" VARCHAR2(200 BYTE),
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;