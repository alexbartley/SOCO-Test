CREATE TABLE sbxtax3.tb_authority_logic_elements (
  authority_logic_element_id NUMBER(10) NOT NULL,
  authority_logic_group_id NUMBER(10) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  "CONDITION" VARCHAR2(10 BYTE) NOT NULL,
  selector VARCHAR2(10 BYTE) NOT NULL,
  "VALUE" NUMBER(10) NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP
) 
TABLESPACE ositax;