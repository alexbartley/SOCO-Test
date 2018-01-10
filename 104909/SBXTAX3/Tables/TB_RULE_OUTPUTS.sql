CREATE TABLE sbxtax3.tb_rule_outputs (
  rule_output_id NUMBER(10) NOT NULL,
  rule_id NUMBER(10) NOT NULL,
  "NAME" VARCHAR2(200 BYTE) NOT NULL,
  "VALUE" VARCHAR2(200 BYTE) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;